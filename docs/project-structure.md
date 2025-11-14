# VOSC Project Structure Documentation

## Overview
This document outlines the complete file structure for the VOSC (Open Source Community at VCE) website project. The application is a full-stack web platform built with React frontend and Node.js backend, featuring user management, contribution tracking, event management, and integrated GSoC organization browsing functionality.

## Technology Stack
- **Frontend**: Next.js (React framework) with App Router
- **Backend**: Node.js with Express.js framework
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT-based with Supabase Auth
- **External APIs**: GitHub API only
- **Internal Features**: GSoC Organizations data managed locally
- **Notifications**: Email (SMTP) and WhatsApp integration

## Root Directory Structure

```
vosc-project/
├── frontend/           # Next.js application
│   ├── public/         # Static assets (images, icons, etc.)
│   ├── src/            # Optional src directory
│   ├── app/            # Next.js App Router directory
│   │   ├── layout.js   # Root layout
│   │   ├── page.js     # Homepage
│   │   ├── globals.css # Global styles
│   │   ├── components/ # Reusable UI components
│   │   ├── lib/        # Utility functions and configurations
│   │   ├── api/        # API routes (if using Next.js API)
│   │   ├── (auth)/     # Route groups for organization
│   │   ├── dashboard/  # Protected routes
│   │   └── admin/      # Admin routes
│   ├── package.json
│   └── README.md
├── backend/            # Node.js API server
│   ├── src/
│   │   ├── controllers/ # Route handlers
│   │   ├── models/      # Database models
│   │   ├── services/    # Business logic services
│   │   ├── middleware/  # Custom middleware
│   │   ├── routes/      # API route definitions
│   │   ├── utils/       # Helper functions
│   │   └── config/      # Configuration files
│   ├── tests/           # Test files
│   ├── package.json
│   └── README.md
├── database/           # Database schema and migrations
│   ├── migrations/     # Database migration files
│   ├── seeds/          # Seed data including GSoC org data
│   └── schema.sql      # Initial schema definition
├── docs/               # Documentation
│   ├── api/            # API documentation
│   ├── frontend/       # Frontend component docs
│   ├── backend/        # Backend service docs
│   └── deployment/     # Deployment guides
├── scripts/            # Utility scripts for data import
├── .gitignore
├── README.md           # Main project README
└── docker-compose.yml  # For local development
```

## Directory Purposes and Responsibilities

### Frontend Directory (`/frontend`)
**Purpose**: Contains the entire React.js application responsible for the user interface and client-side logic.

**Key Components**:
- Public pages (homepage, about, events, etc.)
- User authentication forms
- Member dashboard and profile pages
- Admin dashboard and management interfaces
- GSoC Organizations browser (local data integration)
- PR Quality Assistant interface

**Routes Structure** (Frontend):
- `/` - Homepage
- `/about` - About page
- `/events` - Events listing
- `/events/:id` - Event details
- `/projects` - Projects showcase
- `/resources` - Resources page
- `/join` - Join application form
- `/login` - User login
- `/dashboard` - Member dashboard (protected)
- `/admin/*` - Admin routes (protected)
- `/gsoc` - GSoC Organizations browser (protected)
- `/pr-assistant` - PR Quality Assistant (protected)

### Backend Directory (`/backend`)
**Purpose**: Node.js server handling all server-side logic, API endpoints, database operations, and external API integrations.

**Key Components**:
- Authentication service (JWT)
- User and member management
- Application processing workflow
- Event management and PR tracking
- GitHub API integration for PR sync
- Local GSoC organization data management
- Email and WhatsApp notification service
- Admin tools and analytics

**API Routes Structure** (Backend):
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/me` - Get current user
- `POST /api/applications` - Submit application
- `GET /api/applications` - Get applications (admin)
- `PUT /api/applications/:id/status` - Update application status
- `GET /api/members` - Get member profiles
- `PUT /api/members/:id` - Update member profile
- `GET /api/events` - Get events
- `POST /api/events` - Create event (admin)
- `GET /api/contributions` - Get PR contributions
- `GET /api/leaderboards/:eventId` - Get event leaderboard
- `GET /api/gsoc/orgs` - Get GSoC organizations (from local database)
- `POST /api/pr-assistant/analyze` - Analyze PR for quality
- `GET /api/notifications` - Get user notifications
- `POST /api/admin/announcements` - Create announcement (admin)

### Database Directory (`/database`)
**Purpose**: Contains Supabase database schema definitions, migrations, and seed data for PostgreSQL, including pre-populated GSoC organization data.

**Database Tables**:
- `users` - User accounts and authentication
- `member_profiles` - Extended member information
- `applications` - Membership applications
- `events` - Event definitions and settings
- `contributions` - PR tracking data
- `announcements` - System announcements
- `gsoc_orgs` - GSoC organization data (local storage)

## File Component Documentation

Each major component has detailed documentation in the following sections. The documentation includes:
- Purpose and responsibilities
- Key features and functionality
- Input/output requirements
- Dependencies and integrations
- Security considerations
- Performance requirements

See the individual documentation files in `/docs/frontend/`, `/docs/backend/`, and `/docs/api/` for detailed specifications.

## GSoC Integration Clarification
The GSoC Organizations browser functionality operates using locally stored data within the application database. There is no external API integration; all organization information is managed internally through database seeding and admin tools for data maintenance.
