-- =====================================================
-- VOSC Database - Functions and Triggers
-- =====================================================
-- Helper functions for calculations and automation
-- =====================================================

-- =====================================================
-- FUNCTION: Update Event Participant Scores
-- =====================================================
-- Calculates total score for a member in an event
-- based on their contributions
CREATE OR REPLACE FUNCTION update_event_participant_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Update total score for the member in the event
    UPDATE event_participants
    SET total_score = (
        SELECT COALESCE(SUM(score), 0)
        FROM contributions
        WHERE member_id = COALESCE(NEW.member_id, OLD.member_id)
        AND event_id = COALESCE(NEW.event_id, OLD.event_id)
        AND created_at >= (SELECT start_date FROM events WHERE id = COALESCE(NEW.event_id, OLD.event_id))
        AND created_at <= (SELECT end_date FROM events WHERE id = COALESCE(NEW.event_id, OLD.event_id))
    )
    WHERE event_id = COALESCE(NEW.event_id, OLD.event_id)
    AND member_id = COALESCE(NEW.member_id, OLD.member_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update participant score when contribution score changes
CREATE TRIGGER trigger_update_participant_score
    AFTER INSERT OR UPDATE OF score ON contributions
    FOR EACH ROW
    WHEN (NEW.event_id IS NOT NULL)
    EXECUTE FUNCTION update_event_participant_score();

-- =====================================================
-- FUNCTION: Update Event Leaderboard Ranks
-- =====================================================
-- Updates ranks for all participants in an event
CREATE OR REPLACE FUNCTION update_event_leaderboard_ranks(event_uuid UUID)
RETURNS void AS $$
BEGIN
    WITH ranked_participants AS (
        SELECT 
            id,
            ROW_NUMBER() OVER (ORDER BY total_score DESC, joined_at ASC) as new_rank
        FROM event_participants
        WHERE event_id = event_uuid
    )
    UPDATE event_participants ep
    SET rank = rp.new_rank
    FROM ranked_participants rp
    WHERE ep.id = rp.id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Create Notification for PR Status Change
-- =====================================================
-- Automatically creates notification when PR status changes
CREATE OR REPLACE FUNCTION create_pr_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    notification_type VARCHAR(50);
    notification_title VARCHAR(255);
    notification_message TEXT;
BEGIN
    -- Only create notification if status changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- Determine notification type and message
        CASE NEW.status
            WHEN 'merged' THEN
                notification_type := 'pr_merged';
                notification_title := 'PR Merged Successfully';
                notification_message := 'Your PR "' || NEW.pr_title || '" has been merged';
            WHEN 'closed' THEN
                notification_type := 'pr_closed';
                notification_title := 'PR Closed';
                notification_message := 'Your PR "' || NEW.pr_title || '" has been closed';
            WHEN 'open' THEN
                IF OLD.status IS NULL THEN
                    notification_type := 'pr_opened';
                    notification_title := 'PR Opened';
                    notification_message := 'Your PR "' || NEW.pr_title || '" is now open for review';
                ELSE
                    notification_type := 'pr_updated';
                    notification_title := 'PR Updated';
                    notification_message := 'Your PR "' || NEW.pr_title || '" has been updated';
                END IF;
            ELSE
                RETURN NEW;
        END CASE;
        
        -- Create notification
        INSERT INTO notifications (user_id, type, title, message, data)
        VALUES (
            NEW.member_id,
            notification_type,
            notification_title,
            notification_message,
            jsonb_build_object(
                'prLink', NEW.pr_link,
                'repoName', NEW.repo_owner || '/' || NEW.repo_name,
                'prNumber', NEW.pr_number
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Create notification on PR status change
CREATE TRIGGER trigger_create_pr_notification
    AFTER INSERT OR UPDATE OF status ON contributions
    FOR EACH ROW
    EXECUTE FUNCTION create_pr_status_notification();

-- =====================================================
-- FUNCTION: Calculate Contribution Score
-- =====================================================
-- Calculates score for a contribution based on event scoring rules
-- This is a helper function that can be called from backend
CREATE OR REPLACE FUNCTION calculate_contribution_score(
    contribution_uuid VARCHAR(255),
    event_uuid UUID
)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    contribution_record contributions%ROWTYPE;
    event_record events%ROWTYPE;
    calculated_score DECIMAL(10, 2) := 0;
    base_score DECIMAL(10, 2) := 0;
    complexity_multiplier DECIMAL(10, 2) := 1.0;
    complexity_category VARCHAR(20);
    scoring_rules JSONB;
BEGIN
    -- Get contribution and event records
    SELECT * INTO contribution_record FROM contributions WHERE id = contribution_uuid;
    SELECT * INTO event_record FROM events WHERE id = event_uuid;
    
    IF contribution_record IS NULL OR event_record IS NULL THEN
        RETURN 0;
    END IF;
    
    scoring_rules := event_record.scoring_rules;
    
    -- Base score based on status
    CASE contribution_record.status
        WHEN 'merged' THEN
            base_score := COALESCE((scoring_rules->>'pr_merged')::DECIMAL, 0);
        WHEN 'open' THEN
            base_score := COALESCE((scoring_rules->>'pr_opened')::DECIMAL, 0);
        WHEN 'closed' THEN
            base_score := COALESCE((scoring_rules->>'pr_closed_unmerged')::DECIMAL, 0);
    END CASE;
    
    -- Calculate complexity
    IF (contribution_record.additions + contribution_record.deletions) < 50 
       AND contribution_record.changed_files <= 2 THEN
        complexity_category := 'small';
    ELSIF (contribution_record.additions + contribution_record.deletions) < 200 
          AND contribution_record.changed_files <= 5 THEN
        complexity_category := 'medium';
    ELSE
        complexity_category := 'large';
    END IF;
    
    -- Get complexity multiplier
    IF scoring_rules->'complexity_multiplier' IS NOT NULL THEN
        complexity_multiplier := COALESCE(
            (scoring_rules->'complexity_multiplier'->>complexity_category)::DECIMAL,
            1.0
        );
    END IF;
    
    -- Calculate final score
    calculated_score := base_score * complexity_multiplier;
    
    -- Bonus for addressing reviews (if applicable)
    IF contribution_record.reviews_count > 0 AND scoring_rules->>'review_addressed' IS NOT NULL THEN
        calculated_score := calculated_score + COALESCE(
            (scoring_rules->>'review_addressed')::DECIMAL,
            0
        );
    END IF;
    
    RETURN ROUND(calculated_score, 2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_contribution_score IS 'Calculates contribution score based on event scoring rules';

