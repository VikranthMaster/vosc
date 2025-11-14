# Frontend: Member Dashboard Component

**File Location**: `frontend/src/pages/MemberDashboard.jsx`
**Route**: `/dashboard` (Protected - Members only, FR-19 access control)

## Purpose
The Member Dashboard serves as the central hub for authenticated members to view their contribution statistics, access tools, participate in events, and receive important announcements.

## Functional Requirements to Implement
- FR-20: Display member profile information with editable GitHub and interests
- FR-21: Editable GitHub username and interests fields
- FR-22: Welcome section personalized with member name
- FR-23: Real-time PR contribution statistics (Total PRs, Merged PRs, Open PRs, Issues)
- FR-24: Events participation badges and status
- FR-25: Internal announcements feed

## Layout Structure
```
Member Dashboard Layout
├── Header/Navigation
│   ├── Welcome message: "Welcome back, [Name]!"
│   ├── Profile quick actions dropdown
│   └── Logout button

├── Stats Overview Cards (Top Row)
│   ├── Total PRs Card
│   │   ├── Icon and count
│   │   ├── This month/This week comparisons
│   │   └── Trend indicator (up/down)
│   ├── Merged PRs Card
│   │   ├── Count and percentage
│   │   └── Success rate
│   ├── Open PRs Card
│   │   ├── Active count
│   │   └── Average merge time
│   └── Issues Opened Card
│       ├── Count and breakdown
│       └── Hot repositories

├── Profile Section (Sidebar/Right panel)
│   ├── Member Avatar (GitHub avatar or default)
│   ├── Current rank/status in community
│   ├── Branch and year of study
│   ├── GitHub username (editable)
│   ├── Areas of interest (editable tags)
│   └── Quick profile edit button

├── Main Content Areas

Recent Contributions Section
├── Table/List of latest 5 contributions
│   ├── PR title/link
│   ├── Repository name
│   ├── Status badge (Open/Merged/Closed)
│   ├── Created date
│   ├── Reviews count
│   └── Last updated
└── "View All Contributions" button → dedicated page

Events Participation Section
├── Active Events Cards
│   ├── Event name and dates
│   ├── Member's current score
│   ├── Rank in leaderboard
│   └── Time remaining
├── Past Events Summary
│   ├── Participation badges
│   ├── Best scores achieved
│   └── Certificates earned
└── "View All Events" link

Announcements Section
├── Pinned Important Announcements
│   ├── Priority indicator
│   ├── Title and preview
│   └── Read status
└── Recent Updates
    ├── New features
    ├── Event reminders
    └── Community updates

Quick Actions/Shortcuts
├── PR Quality Assistant button → /pr-assistant
├── GSoC Organizations Browser → /gsoc (if accessible)
├── Join Next Event → opens modal with available events
└── Update Profile → inline editing or modal
```

## Data Requirements

### API Endpoints Used
1. **GET /api/auth/me** - Current user profile data
2. **GET /api/contributions/stats** - PR statistics and recent contributions
3. **GET /api/members/profile** - Extended member profile details
4. **GET /api/events/member/:memberId** - Participated and active events
5. **GET /api/announcements** - Community announcements (filtered for member)
6. **PUT /api/members/profile** - Profile update operations

### Data Structures Expected
**Stats Response Example**:
```json
{
  "totalPRs": 47,
  "mergedPRs": 32,
  "openPRs": 8,
  "issuesOpened": 15,
  "monthlyStats": {
    "thisMonth": 12,
    "lastMonth": 8,
    "trend": "+50%"
  },
  "repositories": {
    "mostActive": "org/project",
    "totalRepos": 15
  }
}
```

**Recent Contributions Response**:
```json
{
  "contributions": [
    {
      "id": "...",
      "title": "Fix bug in authentication",
      "repo": "org/project",
      "pr_link": "https://github.com/...",
      "status": "merged",
      "created_at": "2025-11-10T10:00:00Z",
      "reviews_count": 3,
      "last_updated": "2025-11-12T14:30:00Z"
    }
  ]
}
```

## Interactive Features
- Inline editing for GitHub username and interests
- Expandable stats cards with detailed breakdowns
- Clickable PR links (open in new tab)
- Event enrollment quick actions
- Profile avatar upload (if supported)
- Real-time notifications for new announcements
- Refresh data button for manual sync

## Real-time Updates
- PR stats should auto-refresh every 5-10 minutes
- New announcements appear with notification badges
- Event status updates (scores, ranks) during active competitions
- Live activity feed for recent contributions

## Dependencies
- Authentication context for user data
- API service functions for all endpoints
- Reusable components:
  - `StatCard` for metrics display
  - `ContributionRow` for PR listings
  - `EventCard` for participation tracking
  - `AnnouncementCard` for updates
  - `ProfileEditor` for inline editing

## State Management
- Global auth context for current user
- Local state for UI interactions (expanded sections, loading states)
- React Query or SWR for data fetching and caching
- Optimistic updates for profile changes

## Security Requirements
- Verify user authentication on component mount
- Sanitize all user-generated content
- Validate GitHub username format before updates
- Rate limit profile update requests
- Secure local storage for sensitive data

## Performance Optimization
- Lazy load charts and heavy components
- Cache stats data with appropriate TTL
- Implement virtual scrolling for long contribution lists
- Debounce search and filter operations

## Responsive Design
- Mobile-first layout with collapsible sidebar
- Stats cards stack vertically on small screens
- Touch-friendly interaction areas
- Adjustable font sizes for readability

## Accessibility Features
- Keyboard navigation throughout dashboard
- Screen reader announcements for dynamic updates
- High contrast mode support
- Focus management for modals and edits
- Color-blind friendly color schemes

## Error Handling
- Network error states with retry options
- Empty states for new members (no contributions yet)
- Graceful degradation for failed API calls
- User-friendly error messages

## Integration Points
- GitHub webhook data sync (backend managed)
- Real-time notifications (WebSocket or polling)
- Event leaderboard updates during competitions
- Profile data sync across all member views

## Testing Requirements
- Mock API responses for development
- Unit tests for state management logic
- Integration tests for data fetching
- E2E tests for critical user flows
- Performance tests for loading times
- Accessibility compliance testing

## Future Enhancements
- Dashboard customization options
- Advanced analytics charts
- Contribution timeline visualization
- Achievement badge system
- Social features (activity feed)
- Integration with development tools
