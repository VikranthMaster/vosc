-- =====================================================
-- VOSC Database Schema - Initial Migration
-- =====================================================
-- This migration creates all core tables for the VOSC platform
-- =====================================================

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
-- Extends Supabase Auth with app-specific fields
-- Links to auth.users via UUID
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'member')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE users IS 'User profiles extending Supabase Auth with role and name';
COMMENT ON COLUMN users.id IS 'References auth.users.id from Supabase Auth';
COMMENT ON COLUMN users.role IS 'User role: admin or member';

-- =====================================================
-- 2. MEMBER PROFILES TABLE
-- =====================================================
-- Extended information for accepted members
CREATE TABLE IF NOT EXISTS member_profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    roll_no VARCHAR(50),
    branch VARCHAR(100),
    year VARCHAR(20),
    github_username VARCHAR(255) NOT NULL,
    interests TEXT[],
    bio TEXT,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE member_profiles IS 'Extended profile information for community members';
COMMENT ON COLUMN member_profiles.github_username IS 'Required for PR tracking via GitHub API';

-- =====================================================
-- 3. APPLICATIONS TABLE
-- =====================================================
-- Membership applications (public submissions)
CREATE TABLE IF NOT EXISTS applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    roll_no VARCHAR(50) NOT NULL,
    branch VARCHAR(100) NOT NULL,
    year VARCHAR(20) NOT NULL,
    github_username VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    interests TEXT[],
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    interview_details TEXT,
    admin_notes TEXT,
    processed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE applications IS 'Membership applications submitted by public users';
COMMENT ON COLUMN applications.status IS 'Application status: pending, accepted, or rejected';

-- =====================================================
-- 4. EVENTS TABLE
-- =====================================================
-- Event definitions (competitions, workshops, etc.)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('competition', 'workshop', 'hackathon', 'other')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'upcoming', 'active', 'past', 'cancelled')),
    pr_tracking_enabled BOOLEAN DEFAULT false,
    scoring_rules JSONB,
    whitelisted_repos TEXT[],
    max_participants INTEGER,
    resources JSONB,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE events IS 'Event definitions with scoring rules and configuration';
COMMENT ON COLUMN events.scoring_rules IS 'JSON object with scoring configuration (pr_merged, pr_opened, etc.)';
COMMENT ON COLUMN events.resources IS 'Array of resource objects with title and url';

-- =====================================================
-- 5. EVENT PARTICIPANTS TABLE
-- =====================================================
-- Many-to-many relationship between members and events
CREATE TABLE IF NOT EXISTS event_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_score DECIMAL(10, 2) DEFAULT 0,
    rank INTEGER,
    UNIQUE(event_id, member_id)
);

COMMENT ON TABLE event_participants IS 'Tracks member participation in events and their scores';
COMMENT ON COLUMN event_participants.total_score IS 'Calculated total score for this member in this event';
COMMENT ON COLUMN event_participants.rank IS 'Current rank in event leaderboard (calculated)';

-- =====================================================
-- 6. CONTRIBUTIONS TABLE
-- =====================================================
-- PR tracking data from GitHub
-- Based on schema from docs/backend/pr-tracking-engine.md
CREATE TABLE IF NOT EXISTS contributions (
    id VARCHAR(255) PRIMARY KEY,
    member_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    github_pr_id BIGINT NOT NULL,
    repo_name VARCHAR(255) NOT NULL,
    repo_owner VARCHAR(255) NOT NULL,
    pr_number INTEGER NOT NULL,
    pr_title TEXT NOT NULL,
    pr_link VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('open', 'closed', 'merged')),
    author_github_username VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    merged_at TIMESTAMP WITH TIME ZONE,
    labels JSONB,
    reviewers JSONB,
    reviews_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    additions INTEGER DEFAULT 0,
    deletions INTEGER DEFAULT 0,
    changed_files INTEGER DEFAULT 0,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    score DECIMAL(10, 2) DEFAULT 0,
    metadata JSONB,
    last_synced TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT unique_pr UNIQUE (author_github_username, github_pr_id, repo_owner, repo_name)
);

COMMENT ON TABLE contributions IS 'Tracks all PRs from GitHub for all members';
COMMENT ON COLUMN contributions.id IS 'Unique identifier for the PR (can be composite key)';
COMMENT ON COLUMN contributions.score IS 'Calculated score based on event scoring rules';
COMMENT ON COLUMN contributions.metadata IS 'Additional GitHub API data stored as JSON';

-- =====================================================
-- 7. ANNOUNCEMENTS TABLE
-- =====================================================
-- System-wide announcements
CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    is_pinned BOOLEAN DEFAULT false,
    target_audience VARCHAR(20) NOT NULL DEFAULT 'all' CHECK (target_audience IN ('all', 'members', 'admins')),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE announcements IS 'System announcements visible to users based on target audience';

-- =====================================================
-- 8. GSoC ORGANIZATIONS TABLE
-- =====================================================
-- GSoC organization data (local storage, no external API)
CREATE TABLE IF NOT EXISTS gsoc_orgs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    technologies TEXT[],
    repo_links TEXT[],
    contribution_guidelines VARCHAR(500),
    last_year_participated INTEGER,
    tags TEXT[],
    past_ideas JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE gsoc_orgs IS 'GSoC organization data stored locally (no external API integration)';
COMMENT ON COLUMN gsoc_orgs.past_ideas IS 'JSON array of past project ideas with title and difficulty';

-- =====================================================
-- 9. NOTIFICATIONS TABLE
-- =====================================================
-- User notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('pr_merged', 'pr_opened', 'pr_updated', 'review_requested', 'announcement', 'event_reminder', 'application_status')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE notifications IS 'User notifications for PR updates, announcements, etc.';
COMMENT ON COLUMN notifications.data IS 'Additional context data (prLink, repoName, etc.)';

-- =====================================================
-- 10. CONTENT TABLE
-- =====================================================
-- Admin-editable content for pages (About page, etc.)
CREATE TABLE IF NOT EXISTS content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_key VARCHAR(100) NOT NULL,
    section_key VARCHAR(100) NOT NULL,
    content_data JSONB NOT NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(page_key, section_key)
);

COMMENT ON TABLE content IS 'Admin-editable content for static pages (About page, etc.)';
COMMENT ON COLUMN content.page_key IS 'Page identifier (e.g., about, homepage)';
COMMENT ON COLUMN content.section_key IS 'Section within page (e.g., hero, whoWeAre)';
COMMENT ON COLUMN content.content_data IS 'JSON object containing the content for this section';

-- =====================================================
-- CREATE UPDATED_AT TRIGGER FUNCTION
-- =====================================================
-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_member_profiles_updated_at BEFORE UPDATE ON member_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gsoc_orgs_updated_at BEFORE UPDATE ON gsoc_orgs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_updated_at BEFORE UPDATE ON content
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

