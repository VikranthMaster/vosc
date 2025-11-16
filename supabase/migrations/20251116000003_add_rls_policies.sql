-- =====================================================
-- VOSC Database - Row Level Security (RLS) Policies
-- =====================================================
-- Enables RLS and creates security policies
-- =====================================================

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE gsoc_orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE content ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USERS TABLE POLICIES
-- =====================================================
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- =====================================================
-- MEMBER PROFILES TABLE POLICIES
-- =====================================================
-- Members can view all member profiles
CREATE POLICY "Members can view all profiles"
    ON member_profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'member')
        )
    );

-- Members can update their own profile
CREATE POLICY "Members can update own profile"
    ON member_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Admins can insert/update any profile
CREATE POLICY "Admins can manage all profiles"
    ON member_profiles FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- APPLICATIONS TABLE POLICIES
-- =====================================================
-- Public can create applications
CREATE POLICY "Public can create applications"
    ON applications FOR INSERT
    WITH CHECK (true);

-- Public can view their own application (by email match - simplified)
-- Note: In production, you might want to link applications to user accounts
CREATE POLICY "Users can view own application"
    ON applications FOR SELECT
    USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Only admins can update applications
CREATE POLICY "Admins can update applications"
    ON applications FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- EVENTS TABLE POLICIES
-- =====================================================
-- Public can view events
CREATE POLICY "Public can view events"
    ON events FOR SELECT
    USING (true);

-- Only admins can create/update events
CREATE POLICY "Admins can manage events"
    ON events FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- EVENT PARTICIPANTS TABLE POLICIES
-- =====================================================
-- Members can view participants for events they're in
CREATE POLICY "Members can view event participants"
    ON event_participants FOR SELECT
    USING (
        member_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Members can join events (insert)
CREATE POLICY "Members can join events"
    ON event_participants FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'member'
        )
        AND member_id = auth.uid()
    );

-- Admins can manage all participants
CREATE POLICY "Admins can manage participants"
    ON event_participants FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- CONTRIBUTIONS TABLE POLICIES
-- =====================================================
-- Members can view their own contributions
CREATE POLICY "Members can view own contributions"
    ON contributions FOR SELECT
    USING (
        member_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Only system (via service role) can insert/update contributions
-- Note: This should be done via backend service with service role key
-- For now, admins can manage
CREATE POLICY "Admins can manage contributions"
    ON contributions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- ANNOUNCEMENTS TABLE POLICIES
-- =====================================================
-- Users can view announcements based on target audience
CREATE POLICY "Users can view relevant announcements"
    ON announcements FOR SELECT
    USING (
        target_audience = 'all'
        OR (target_audience = 'members' AND EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'member')
        ))
        OR (target_audience = 'admins' AND EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
        ))
        OR (expires_at IS NULL OR expires_at > NOW())
    );

-- Only admins can create/update announcements
CREATE POLICY "Admins can manage announcements"
    ON announcements FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- GSoC ORGANIZATIONS TABLE POLICIES
-- =====================================================
-- Members can view GSoC organizations
CREATE POLICY "Members can view GSoC orgs"
    ON gsoc_orgs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'member')
        )
    );

-- Only admins can manage GSoC organizations
CREATE POLICY "Admins can manage GSoC orgs"
    ON gsoc_orgs FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- NOTIFICATIONS TABLE POLICIES
-- =====================================================
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- System can insert notifications (via service role)
-- Admins can also insert for any user
CREATE POLICY "Admins can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- CONTENT TABLE POLICIES
-- =====================================================
-- Public can view content
CREATE POLICY "Public can view content"
    ON content FOR SELECT
    USING (true);

-- Only admins can update content
CREATE POLICY "Admins can manage content"
    ON content FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

