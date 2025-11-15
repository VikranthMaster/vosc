-- =====================================================
-- VOSC Database - Indexes Migration
-- =====================================================
-- Creates indexes for performance optimization
-- =====================================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Member profiles indexes
CREATE INDEX IF NOT EXISTS idx_member_profiles_github_username ON member_profiles(github_username);
CREATE INDEX IF NOT EXISTS idx_member_profiles_is_active ON member_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_member_profiles_branch ON member_profiles(branch);

-- Applications indexes
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON applications(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_email ON applications(email);

-- Events indexes
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);

-- Event participants indexes
CREATE INDEX IF NOT EXISTS idx_event_participants_event_id ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_member_id ON event_participants(member_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_total_score ON event_participants(event_id, total_score DESC);

-- Contributions indexes (critical for PR tracking)
CREATE INDEX IF NOT EXISTS idx_contributions_member_id ON contributions(member_id);
CREATE INDEX IF NOT EXISTS idx_contributions_event_id ON contributions(event_id);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON contributions(status);
CREATE INDEX IF NOT EXISTS idx_contributions_created_at ON contributions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contributions_last_synced ON contributions(last_synced);
CREATE INDEX IF NOT EXISTS idx_contributions_repo_owner_name ON contributions(repo_owner, repo_name);
CREATE INDEX IF NOT EXISTS idx_contributions_author_github ON contributions(author_github_username);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- Announcements indexes
CREATE INDEX IF NOT EXISTS idx_announcements_target_audience ON announcements(target_audience);
CREATE INDEX IF NOT EXISTS idx_announcements_is_pinned ON announcements(is_pinned);
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_expires_at ON announcements(expires_at);

-- GSoC organizations indexes
CREATE INDEX IF NOT EXISTS idx_gsoc_orgs_category ON gsoc_orgs(category);
CREATE INDEX IF NOT EXISTS idx_gsoc_orgs_name ON gsoc_orgs(name);

-- Content indexes
CREATE INDEX IF NOT EXISTS idx_content_page_key ON content(page_key);

