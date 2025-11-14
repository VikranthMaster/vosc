# Frontend: PR Quality Assistant Component

**File Location**: `frontend/src/pages/PRQualityAssistant.jsx`
**Route**: `/pr-assistant` (Protected - Members only)

## Purpose
The PR Quality Assistant helps members improve their pull request quality before submitting to actual repositories. It analyzes PR components and provides actionable suggestions for better acceptance rates in open source projects.

## Functional Requirements to Implement
- FR-44: Accept PR diff/commit link/description input
- FR-45: Analyze for linting, file structure, commit hygiene, links, formatting, conventional commits
- FR-46: Provide specific suggestions to improve PR quality
- FR-47: Require passing the check before event submissions

## Layout Structure
```
PR Quality Assistant Layout
├── Header Section
│   ├── Title: "PR Quality Checker"
│   ├── Subtitle: "Analyze and improve your PR before submission"
│   └── Instructions tooltip/help

├── Input Section
│   ├── Tab-based Input Methods
│   │   ├── "Paste PR Diff" tab
│   │   │   ├── Large textarea for diff content
│   │   │   └── Instructions: paste output of `git diff`
│   │   ├── "Commit Link" tab
│   │   │   ├── GitHub PR/Commit URL input
│   │   │   └── Auto-fetch diff from GitHub API
│   │   └── "Manual Description" tab
│   │       ├── PR Title field
│   │       ├── Description textarea
│   │       ├── Changed files list (manual entry)
│   │       └── Commit messages
│   └── Analyze Button
│       ├── "Check Quality" (primary action)
│       └── Disable when no input provided

├── Analysis Results Section
│   ├── Overall Score Card
│   │   ├── Quality Score: 0-100 (colored indicator)
│   │   ├── Grade: Poor/Fair/Good/Excellent
│   │   └── Recommendation: Ready to Submit / Needs Work
│   ├── Checklist Status
│   │   ├── ✅ Passed Item
│   │   ├── ❌ Failed Item with fix suggestion
│   │   └── ⚠️ Warning Item with optional improvement
│   └── Detailed Feedback Sections
│       ├── Linting Issues
│       ├── Code Formatting Problems
│       ├── File Structure Concerns
│       ├── Commit Message Quality
│       ├── Documentation Gaps
│       └── Link Validation

├── Improvement Suggestions Panel
│   ├── Priority-based recommendations (Critical/Important/Minor)
│   ├── Step-by-step fix instructions
│   ├── Code examples for corrections
│   ├── Links to relevant documentation/guides
│   └── Quick apply buttons (where possible)

└── Event Submission Integration
    ├── Checkbox: "Required for [Event Name]" when accessed during event
    ├── Passing threshold indicator
    ├── Submit to Event button (disabled until passing score)
    └── Generate Quality Report (PDF/download)
```

## Analysis Criteria Implementation

### 1. Linting (FR-45)
- Check for syntax errors
- Identify unused variables, imports
- Flag potential security issues
- Language-specific linting rules

### 2. File Structure (FR-45)
- Verify files are in appropriate directories
- Check for file naming conventions
- Validate file types match extensions
- Ensure no unrelated files included

### 3. Commit Hygiene (FR-45)
- Check commit message format (conventional commits)
- Verify descriptive commit messages
- Flag overly large commits
- Check commit frequency/logic grouping

### 4. Link Validation (FR-45)
- Test all URLs in PR description
- Validate GitHub issue/PR references
- Check documentation links
- Verify image paths

### 5. Formatting (FR-45)
- Code indentation consistency
- Import organization
- Trailing whitespace removal
- Line length compliance

### 6. Conventional Commits (FR-45)
- Validate commit format: `type(scope): description`
- Check allowed types: feat, fix, docs, style, refactor, test, chore
- Verify body and footer formatting
- Check for breaking change indicators

## Input/Output Specifications

### Input Data Types
- **PR Diff**: Raw git diff output (string)
- **Commit Link**: GitHub URL (must be valid GitHub.com/pr or /commit)
- **Manual Data**: Structured object with title, description, files, commits

### API Integration
**POST /api/pr-assistant/analyze**
```json
{
  "inputType": "diff|url|manual",
  "data": {
    "diff": "...", // for inputType: "diff"
    "url": "https://github.com/.../pull/123", // for inputType: "url"
    "title": "...",
    "description": "...",
    "changedFiles": ["file1.js", "file2.py"],
    "commits": ["feat: add login", "fix: handle error"]
  }
}
```

**Response Structure**:
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
      "file": "src/components/Button.jsx",
      "line": 5,
      "description": "Remove unused React import",
      "fix": "import { useState } from 'react';"
    }
  ],
  "suggestions": [
    {
      "priority": "important",
      "title": "Improve commit message",
      "advice": "Use conventional commit format: 'fix(ui): resolve button hover state'",
      "links": ["https://conventionalcommits.org"]
    }
  ],
  "metadata": {
    "analyzedAt": "2025-11-14T23:30:00Z",
    "filesAnalyzed": 5,
    "linesOfCode": 247
  }
}
```

## User Experience Flow
1. User selects input method and provides data
2. Loading spinner during analysis (API call)
3. Results display with color-coded score
4. Expandable sections for detailed feedback
5. Interactive suggestions with copy-to-clipboard
6. Option to re-analyze after fixes
7. Export quality report for records

## Dependencies
- CodeMirror or Monaco Editor for diff input/display
- Marked.js or similar for markdown rendering
- File icons library for file type visualization
- Notification system for analysis results
- API service functions for analysis endpoints

## Security Considerations
- Sanitize all user input to prevent XSS
- Validate GitHub URLs before making external requests
- Rate limit analysis requests per user
- Do not store sensitive PR content in logs
- Secure the API analysis endpoint

## Performance Requirements
- Analysis completion within 5-10 seconds
- Support large diff sizes (up to 100kb)
- Cache external GitHub data where possible
- Asynchronous processing for heavy analyses
- Progressive loading of results

## Responsive Design
- Mobile-optimized input areas
- Collapsible result sections for small screens
- Touch-friendly action buttons
- Readable code snippets on all devices

## Accessibility Features
- Keyboard navigation throughout interface
- Screen reader support for analysis results
- High contrast indicators for pass/fail status
- Clear labeling of all form controls
- Color-blind friendly color schemes

## Integration with Event System
- Mandatory check for PR-based events (Bug Blitz, etc.)
- Score threshold enforcement before event submission
- Event-specific quality criteria (configurable)
- Leaderboard integration for quality-focused events

## Error Handling
- Invalid input format detection
- GitHub API rate limit handling
- External service unavailability fallback
- User-friendly error messages with recovery options

## Testing Requirements
- Unit tests for analysis algorithms
- Integration tests with mock GitHub API
- E2E tests for complete analysis workflow
- Load testing for performance benchmarks
- Accessibility testing for WCAG compliance

## Future Enhancements
- Real-time diff analysis as user types
- Integration with popular linters (ESLint, Prettier)
- AI-powered suggestion generation
- Team/company-specific rule sets
- Historical analysis tracking
- PR template generation assistance
