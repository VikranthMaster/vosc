# API Routes Documentation

## Overview
This document outlines all REST API endpoints for the VOSC backend, organized by functional areas. Each endpoint includes request/response formats, authentication requirements, and implementation notes.

## Authentication
Most endpoints require authentication via JWT tokens in Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Base URL
All endpoints are prefixed with `/api`

## 1. Authentication Routes

### POST `/api/auth/login`
**Purpose**: Authenticate user and return JWT token
**Access**: Public

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "member"
  },
  "expiresIn": 3600
}
```

### POST `/api/auth/register`
**Purpose**: Register new user (admin use only)
**Access**: Admin only

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "secure_password",
  "role": "member"
}
```

### GET `/api/auth/me`
**Purpose**: Get current authenticated user details
**Access**: Authenticated users

**Response (200)**:
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "user@example.com",
  "role": "member",
  "profile": {
    "branch": "CSE",
    "year": "3rd",
    "github_username": "johndoe",
    "interests": ["web", "mobile"]
  }
}
```

### POST `/api/auth/forgot-password`
**Purpose**: Request password reset
**Access**: Public

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

## 2. Application Management Routes

### POST `/api/applications`
**Purpose**: Submit membership application (FR-13, FR-14)
**Access**: Public
**Requirements**: FR-13 complete form with academic + GitHub + interests

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "rollNo": "CB.EN.U4CSE12345",
  "branch": "CSE",
  "year": "3rd",
  "githubUsername": "johndoe",
  "reason": "I want to contribute to open source...",
  "interests": ["web-development", "data-science"]
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "applicationId": 123,
  "status": "pending",
  "message": "Application submitted successfully"
}
```

### GET `/api/applications`
**Purpose**: Get all applications (admin view)
**Access**: Admin only
**Query Params**:
- `status`: pending|accepted|rejected
- `limit`: number
- `offset`: number

**Response (200)**:
```json
{
  "applications": [
    {
      "id": 123,
      "name": "John Doe",
      "email": "john@example.com",
      "githubUsername": "johndoe",
      "branch": "CSE",
      "year": "3rd",
      "status": "pending",
      "submittedAt": "2025-11-10T10:00:00Z",
      "reason": "Application reason..."
    }
  ],
  "total": 15,
  "page": 1,
  "limit": 10
}
```

### PUT `/api/applications/:id/status`
**Purpose**: Update application status (admin action)
**Access**: Admin only

**Request Body**:
```json
{
  "status": "accepted|rejected|pending",
  "interviewDetails": "Optional interview notes",
  "adminNotes": "Internal admin notes"
}
```

## 3. Member Management Routes

### GET `/api/members`
**Purpose**: Get all members list
**Access**: Admin only

**Response (200)**:
```json
{
  "members": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "github_username": "johndoe",
      "branch": "CSE",
      "year": "3rd",
      "joinedAt": "2025-01-15",
      "isActive": true,
      "contributionStats": {
        "totalPRs": 25,
        "mergedPRs": 18
      }
    }
  ]
}
```

### GET `/api/members/profile`
**Purpose**: Get current member's extended profile
**Access**: Current member

**Response (200)**:
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "profile": {
    "branch": "CSE",
    "year": "3rd",
    "github_username": "johndoe",
    "interests": ["web", "mobile"],
    "bio": "Passionate about open source...",
    "avatar_url": "https://github.com/johndoe.png"
  },
  "stats": {
    "totalPRs": 25,
    "mergedPRs": 18,
    "openPRs": 4,
    "issuesOpened": 12,
    "repositories": ["org/project1", "org/project2"]
  },
  "recentContributions": [
    {
      "title": "Fix login bug",
      "repo": "org/project1",
      "status": "merged",
      "createdAt": "2025-11-10"
    }
  ]
}
```

### PUT `/api/members/profile`
**Purpose**: Update member profile (FR-20, FR-21)
**Access**: Current member

**Request Body**:
```json
{
  "github_username": "johndoe_updated",
  "interests": ["web", "cloud", "ai"],
  "bio": "Updated bio..."
}
```

## 4. Events Management Routes

### GET `/api/events`
**Purpose**: Get all events with filtering
**Access**: All users (public view), Members (detailed view)

**Query Params**:
- `type`: upcoming|past|active
- `limit`: 10
- `page`: 1

**Response (200)**:
```json
{
  "events": [
    {
      "id": 1,
      "title": "Bug Blitz 2025",
      "description": "Month-long bug fixing competition",
      "type": "competition",
      "startDate": "2025-02-01",
      "endDate": "2025-02-28",
      "status": "upcoming",
      "prTrackingEnabled": true,
      "scoringRules": {
        "prMerged": 10,
        "prOpened": 3
      },
      "maxParticipants": 100,
      "currentParticipants": 45,
      "resources": [
        {
          "title": "Event Guidelines",
          "url": "https://docs.example.com/guidelines"
        }
      ]
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalEvents": 25
  }
}
```

### POST `/api/events`
**Purpose**: Create new event
**Access**: Admin only

**Request Body**:
```json
{
  "title": "Hacktober Fest Prep",
  "description": "Prepare for Hacktoberfest",
  "type": "workshop",
  "startDate": "2025-09-01",
  "endDate": "2025-09-30",
  "prTrackingEnabled": false,
  "scoringRules": {},
  "maxParticipants": 50,
  "resources": [
    {"title": "GitHub Guide", "url": "https://guides.github.com"}
  ]
}
```

### GET `/api/events/member/:memberId`
**Purpose**: Get events for specific member (participated/participating)
**Access**: Member (own data) or Admin

### GET `/api/leaderboards/:eventId`
**Purpose**: Get leaderboard for event (FR-62, FR-63)
**Access**: All users (during event), Members always

**Response (200)**:
```json
{
  "event": {
    "id": 1,
    "title": "Bug Blitz 2025",
    "currentRanking": true
  },
  "leaderboard": [
    {
      "rank": 1,
      "memberId": 5,
      "name": "Alice Johnson",
      "totalPRs": 28,
      "mergedPRs": 24,
      "totalScore": 285.5,
      "repositories": ["org/project1", "org/project2"],
      "lastPRDate": "2025-11-12"
    },
    {
      "rank": 2,
      "memberId": 21,
      "name": "Bob Smith",
      "totalPRs": 31,
      "mergedPRs": 21,
      "totalScore": 265.0,
      "repositories": ["org/project3"],
      "lastPRDate": "2025-11-11"
    }
  ],
  "userRank": {
    "rank": 15,
    "score": 95,
    "prs": 12
  }
}
```

## 5. Contributions Tracking Routes

### GET `/api/contributions`
**Purpose**: Get PR contributions with filtering
**Access**: Member (own contributions only), Admin (all)

**Query Params**:
- `memberId`: specific member (admin only)
- `status`: open|closed|merged
- `repo`: specific repository
- `eventId`: filter by event
- `limit`: 20
- `page`: 1

**Response (200)**:
```json
{
  "contributions": [
    {
      "id": "pr_12345",
      "memberId": 5,
      "memberName": "Alice Johnson",
      "repoName": "org/project1",
      "repoOwner": "organization",
      "prNumber": 156,
      "prTitle": "Fix authentication bug",
      "prLink": "https://github.com/org/project1/pull/156",
      "status": "merged",
      "createdAt": "2025-11-10T10:30:00Z",
      "updatedAt": "2025-11-12T14:20:00Z",
      "mergedAt": "2025-11-12T14:20:00Z",
      "reviewsCount": 3,
      "commentsCount": 12,
      "additions": 85,
      "deletions": 23,
      "changedFiles": 3,
      "labels": ["bug", "auth"],
      "score": 15.5
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 245
  },
  "filters": {
    "status": "merged",
    "dateRange": "last-month"
  }
}
```

### GET `/api/contributions/stats`
**Purpose**: Get aggregated statistics (FR-23)
**Access**: Member (own stats), Admin

## 6. GSoC Organizations Routes

### GET `/api/gsoc/orgs`
**Purpose**: Get all GSoC organizations (FR-41, FR-42)
**Access**: Members only (protected)

**Query Params**:
- `category`: web|mobile|ai|etc
- `year`: specific year
- `tech`: specific technology
- `search`: search in name/description

**Response (200)**:
```json
{
  "organizations": [
    {
      "id": "gsoc_org_001",
      "name": "CNCF",
      "category": "cloud-native",
      "technologies": ["kubernetes", "docker", "go"],
      "repoLinks": [
        "https://github.com/cncf/project1",
        "https://github.com/cncf/project2"
      ],
      "description": "Cloud Native Computing Foundation...",
      "pastIdeas": [
        {
          "title": "Kubernetes Scheduler Improvements",
          "difficulty": "hard"
        }
      ],
      "contributionGuidelines": "https://contribute.cncf.io",
      "lastYearParticipated": 2024,
      "tags": ["kubernetes", "cloud", "distributed"]
    }
  ],
  "categories": ["web", "mobile", "ai", "cloud"],
  "totalOrgs": 215
}
```

### GET `/api/gsoc/orgs/:id`
**Purpose**: Get detailed org info
**Access**: Members only

## 7. PR Quality Assistant Routes

### POST `/api/pr-assistant/analyze`
**Purpose**: Analyze PR quality (FR-44 to FR-46)
**Access**: Members only

**Request Body**:
```json
{
  "inputType": "diff|url|manual",
  "data": {
    "diff": "git diff output here",
    "url": "https://github.com/org/repo/pull/123",
    "title": "Manual PR title",
    "description": "PR description...",
    "changedFiles": ["file1.js", "file2.py"],
    "commits": ["feat: add login", "fix: handle error"]
  }
}
```

**Response (200)**:
```json
{
  "overallScore": 85,
  "grade": "Good",
  "recommendation": "Ready to Submit",
  "passedChecks": 12,
  "totalChecks": 15,
  "issues": [
    {
      "category": "linting",
      "severity": "critical",
      "title": "Unused import detected",
      "file": "src/Button.jsx",
      "line": 5,
      "description": "Remove unused React import",
      "fix": "import { useState } from 'react';"
    }
  ],
  "suggestions": [
    {
      "priority": "important",
      "title": "Improve commit message",
      "advice": "Use conventional commit format"
    }
  ]
}
```

## 8. Content Management Routes (Admin)

### GET `/api/content/about`
**Purpose**: Get about page content (FR-8)
**Access**: All users

### PUT `/api/content/about`
**Purpose**: Update about page content (admin)
**Access**: Admin only

## 9. Notification Routes

### GET `/api/notifications`
**Purpose**: Get user notifications
**Access**: Authenticated users

**Response (200)**:
```json
{
  "notifications": [
    {
      "id": 456,
      "type": "pr_merged",
      "title": "PR Merged Successfully",
      "message": "Your PR 'Fix login bug' has been merged",
      "read": false,
      "createdAt": "2025-11-12T14:00:00Z",
      "data": {
        "prLink": "https://github.com/org/repo/pull/123",
        "repoName": "org/repo"
      }
    }
  ],
  "unreadCount": 3
}
```

### PUT `/api/notifications/:id/read`
**Purpose**: Mark notification as read
**Access**: Notification owner

## 10. Admin Analytics Routes

### GET `/api/admin/analytics/overview`
**Purpose**: Get dashboard overview stats
**Access**: Admin only

**Response (200)**:
```json
{
  "overview": {
    "totalMembers": 47,
    "pendingApplications": 12,
    "activeEvents": 2,
    "totalPRs": 1247,
    "monthlyGrowth": "+15%"
  },
  "trends": {
    "prActivity": [
      {"month": "2025-09", "count": 98},
      {"month": "2025-10", "count": 134},
      {"month": "2025-11", "count": 187}
    ]
  }
}
```

### GET `/api/admin/analytics/pr-stats`
**Purpose**: Get detailed PR analytics (FR-70)
**Access**: Admin only

### GET `/api/admin/analytics/member-activity`
**Purpose**: Get member activity reports
**Access**: Admin only

## Error Response Format
All endpoints return errors in consistent format:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  }
}
```

## Rate Limiting
- Public endpoints: 100 requests/hour per IP
- Member endpoints: 1000 requests/hour per user
- Admin endpoints: 5000 requests/hour per user

## Pagination
List endpoints use cursor-based pagination:
```json
{
  "data": [...],
  "cursor": "next_cursor_value",
  "hasMore": false
}
```

## Date Format
All dates use ISO 8601 format: `YYYY-MM-DDTHH:mm:ss.sssZ`
