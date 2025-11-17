# Backend: PR Tracking Engine Service

**File Location**: `backend/src/services/PRTrackingEngine.js`
**Purpose**: Automated system to track and sync pull request data for all VOSC members across public GitHub repositories.

## Functional Requirements Implementation
- FR-50: Track ALL PRs raised by ALL members across ANY public GitHub repository
- FR-51: Automatic sync every 5-10 minutes via background cron job
- FR-52: Store comprehensive PR details including repository, link, status, dates, labels, reviews
- FR-53: Real-time notifications for PR status changes (open/update/merge/close/review)
- FR-54: Multiple notification types via email and WhatsApp

## Architecture Overview
```
PR Tracking Engine Architecture
├── Cron Scheduler (5-10 min intervals)
│   ├── Triggers sync process
│   └── Manages worker processes
│
├── GitHub API Client
│   ├── Authenticated requests to GitHub API
│   ├── Rate limiting and retry logic
│   ├── Webhook event processing (optional)
│
├── Data Processor
│   ├── Fetch member GitHub usernames
│   ├── Query PRs by author across all repos
│   ├── Transform GitHub API data to internal format
│   ├── Deduplication and conflict resolution
│   └── Status change detection
│
├── Database Integration
│   ├── Contributions table updates
│   ├── Event-specific scoring calculations
│   ├── Member statistics aggregation
│   └── Historical data retention
│
├── Notification Service
│   ├── Event-driven notifications
│   ├── Template-based message generation
│   ├── Email/ WhatsApp dispatching
│   └── Failure handling and retries
│
└── Analytics Engine
    ├── Generate dashboard statistics
    ├── Leaderboard calculations for events
    ├── Trend analysis and reporting
    └── Performance metrics tracking
```

## GitHub API Integration

### Authentication
- **Personal Access Tokens**: Securely stored, rotated periodically
- **Rate Limiting**: Handle 5000/hour limit with queue management
- **Fallback Strategies**: Graceful degradation on API failures

### API Endpoints Used
1. **Search API**: `GET /search/issues?q=author:{username}+type:pr`
   - Basic PR discovery across all repos
   - Limited to 1000 results per query
   - Used for initial member onboarding

2. **Repository PRs**: `GET /repos/{owner}/{repo}/pulls`
   - Detailed PR information with full metadata
   - Used for comprehensive data collection
   - Supports pagination for large repositories

3. **Individual PR Details**: `GET /repos/{owner}/{repo}/pulls/{number}`
   - Complete PR data including reviews, labels, timeline
   - Fetched for status updates and detailed analysis

### Data Synchronization Flow
1. **Member Discovery**: Query database for all active members with GitHub usernames
2. **PR Collection**: For each member, fetch recent PRs (last 30 days initially, then incremental)
3. **Data Comparison**: Compare fetched data with existing database records
4. **Change Detection**: Identify new PRs, status changes, updates
5. **Database Updates**: Insert new records, update existing ones
6. **Notification Triggering**: Queue notifications for all detected changes

## Database Schema Integration

### Contributions Table Structure
```sql
CREATE TABLE contributions (
    id VARCHAR(255) PRIMARY KEY,
    member_id INT NOT NULL,
    github_pr_id INT NOT NULL,
    repo_name VARCHAR(255) NOT NULL,
    repo_owner VARCHAR(255) NOT NULL,
    pr_number INT NOT NULL,
    pr_title TEXT NOT NULL,
    pr_link VARCHAR(500) NOT NULL,
    status ENUM('open', 'closed', 'merged') NOT NULL,
    author_github_username VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    closed_at DATETIME NULL,
    merged_at DATETIME NULL,
    labels JSON, -- Store as JSON array
    reviewers JSON, -- Store as JSON array
    reviews_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    additions INT DEFAULT 0,
    deletions INT DEFAULT 0,
    changed_files INT DEFAULT 0,
    event_id INT NULL, -- For event-specific PRs
    score DECIMAL(10,2) DEFAULT 0, -- Calculated score
    metadata JSON, -- Additional API data
    last_synced DATETIME NOT NULL,
    UNIQUE KEY unique_pr (author_github_username, github_pr_id, repo_owner, repo_name)
);
```

### Data Processing Logic
- **Deduplication**: Use composite unique key preventing duplicate entries
- **Status Mapping**: Map GitHub PR states to internal enumeration
- **Date Handling**: Properly convert GitHub timestamps to database format
- **JSON Serialization**: Store complex data (labels, reviewers) as JSON

## Event-Based PR Tracking (FR-60, FR-61)

### Event Configuration
Events are defined with date ranges and scoring rules stored in database.

**Example Event Configuration**:
```json
{
  "id": 1,
  "name": "Bug Blitz 2025",
  "start_date": "2025-02-01",
  "end_date": "2025-02-28",
  "scoring_rules": {
    "pr_merged": 10,
    "pr_opened": 3,
    "pr_closed_unmerged": -2,
    "review_addressed": 2,
    "complexity_multiplier": {
      "small": 1,
      "medium": 1.5,
      "large": 2
    }
  },
  "whitelisted_repos": ["org/project1", "org/project2"]
}
```

### Scoring Algorithm Implementation
```javascript
function calculatePRScore(prData, eventConfig) {
    let baseScore = 0;
    
    // Base scoring based on status
    switch(prData.status) {
        case 'merged': baseScore = eventConfig.scoring_rules.pr_merged; break;
        case 'opened': baseScore = eventConfig.scoring_rules.pr_opened; break;
        case 'closed': baseScore = eventConfig.scoring_rules.pr_closed_unmerged; break;
    }
    
    // Complexity multiplier
    const complexity = assessComplexity(prData);
    baseScore *= eventConfig.scoring_rules.complexity_multiplier[complexity];
    
    // Bonus for addressing review comments
    if (prData.reviews_addressed) {
        baseScore += eventConfig.scoring_rules.review_addressed;
    }
    
    return Math.round(baseScore * 100) / 100;
}

function assessComplexity(prData) {
    const totalLines = prData.additions + prData.deletions;
    const fileCount = prData.changed_files;
    
    if (totalLines < 50 && fileCount <= 2) return 'small';
    if (totalLines < 200 && fileCount <= 5) return 'medium';
    return 'large';
}
```

### Leaderboard Generation (FR-62, FR-63)
Automatic rankings calculated based on total scores within event timeframe.

**Query Example**:
```sql
SELECT 
    m.name,
    COUNT(*) as total_prs,
    COUNT(CASE WHEN status = 'merged' THEN 1 END) as merged_prs,
    SUM(score) as total_score,
    GROUP_CONCAT(DISTINCT repo_name) as repos
FROM contributions c
JOIN members m ON c.member_id = m.id
WHERE c.created_at BETWEEN :event_start AND :event_end
AND (event_id = :event_id OR :event_id IS NULL)
GROUP BY c.member_id
ORDER BY total_score DESC, merged_prs DESC;
```

## Notification System Integration (FR-53, FR-54)

### Event Types and Triggers
- **PR Opened**: Immediate notification when PR is created
- **PR Updated**: When PR content changes (title, description, code)
- **PR Merged**: When PR is successfully merged
- **PR Closed**: When PR is closed without merge
- **Review Requested**: When member is requested for review
- **Review Submitted**: When someone reviews their PR

### Message Templates
**Email Subject Templates**:
- PR Opened: "Your PR is now open for review: {title}"
- PR Merged: "🎉 Your PR has been merged! {title}"
- Review Submitted: "New review on your PR: {title}"

**WhatsApp Message Format**:
```
VOSC PR Tracker

📌 *{PR Title}*
📂 {Repository}
📊 Status: {STATUS}
🔗 {PR Link}

{Additional context based on event type}
```

### Notification Queue Architecture
- **Redis Queue**: Store notification payloads for processing
- **Worker Processes**: Dedicated workers for email/WhatsApp sending
- **Retry Logic**: Exponential backoff for failed deliveries
- **Rate Limiting**: Respect external service limits
- **Template Engine**: Dynamic content insertion

## Cron Job Implementation

### Configuration
```javascript
// config/cron.js
const prSyncSchedule = {
    // Run every 5 minutes during active hours
    schedule: '*/5 * * * *',
    timezone: 'Asia/Kolkata',
    enabled: true,
    
    // Alternative: Run every 10 minutes constantly
    // schedule: '*/10 * * * *'
};
```

### Cron Worker Process
```javascript
// workers/pr-sync-worker.js
async function runPRSync() {
    console.log('Starting PR sync cycle...');
    
    try {
        // 1. Get active members
        const members = await MemberService.getActiveMembers();
        
        // 2. Process each member
        for (const member of members) {
            if (member.github_username) {
                await syncMemberPRs(member);
            }
        }
        
        // 3. Update event leaderboards
        await updateEventLeaderboards();
        
        console.log('PR sync cycle completed');
    } catch (error) {
        console.error('PR sync failed:', error);
        // Alert admin via notification service
    }
}
```

## Error Handling and Recovery

### API Failure Handling
- **Rate Limiting**: Queue requests and implement backoff
- **Network Errors**: Retry with exponential backoff
- **Authentication Errors**: Rotate tokens and alert admin
- **Incomplete Data**: Log warnings and continue processing

### Data Integrity
- **Transaction Management**: Wrap database updates in transactions
- **Rollback Capability**: Maintain audit logs for recovery
- **Data Validation**: Verify all required fields before insertion

### Monitoring and Alerts
- **Health Checks**: Regular self-diagnosis endpoints
- **Metrics Collection**: Track sync success rates, processing times
- **Alert System**: Notify admin when thresholds are breached

## Performance Optimization

### Database Optimizations
- **Indexing Strategy**: Index on commonly queried columns
- **Batch Processing**: Update multiple records in single transactions
- **Connection Pooling**: Reuse database connections efficiently

### API Optimization
- **Concurrent Processing**: Process multiple members simultaneously
- **Incremental Sync**: Only fetch recent changes after initial population
- **Caching Layer**: Cache GitHub responses where possible
- **Request Deduplication**: Avoid redundant API calls

### Scalability Considerations
- **Horizontal Scaling**: Design for multiple worker instances
- **Queue Partitioning**: Separate queues for different priority levels
- **Load Balancing**: Distribute processing across multiple servers

## Security Measures

### Data Protection
- **Encryption**: Encrypt sensitive configuration data
- **Access Control**: Restrict database operations to necessary permissions
- **Audit Logging**: Log all data modifications and system access

### External API Security
- **Token Security**: Secure storage and rotation of GitHub tokens
- **Request Validation**: Validate all input parameters
- **Rate Limit Respect**: Comply with GitHub's API limits

## Testing and Quality Assurance

### Unit Testing
- **Mock External APIs**: Simulate GitHub responses for testing
- **Database Mocking**: Test database operations without live DB
- **Error Scenario Testing**: Verify behavior under failure conditions

### Integration Testing
- **End-to-End Sync**: Test complete sync cycles with real data
- **Notification Testing**: Verify email/WhatsApp delivery
- **Event Scoring Testing**: Validate leaderboard calculations

### Load Testing
- **Performance Benchmarks**: Measure sync time vs data volume
- **Concurrency Testing**: Test multiple sync processes simultaneously
- **Resource Monitoring**: Track memory and CPU usage during operations

## Monitoring and Maintenance

### Key Metrics to Track
- Sync cycle duration and success rate
- Number of PRs processed per cycle
- API call count and rate limit usage
- Database operation performance
- Notification delivery success rates
- Error rates and types

### Maintenance Procedures
- **GitHub Token Rotation**: Periodic token refresh process
- **Database Cleanup**: Remove old sync logs and temporary data
- **Performance Tuning**: Regular query optimization reviews
- **Security Updates**: Keep dependencies up-to-date

## Future Enhancements
- **Webhook Integration**: Real-time PR updates via GitHub webhooks
- **Machine Learning Scoring**: Intelligent PR complexity assessment
- **Multi-Platform Support**: Track PRs on GitLab, Bitbucket
- **Advanced Analytics**: Trend analysis and predictive insights
- **Contributor Insights**: Identify mentoring opportunities
- **Automated Badging**: Achievement system for consistent contribution
