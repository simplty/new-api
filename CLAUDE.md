# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

New API is a next-generation AI model gateway and asset management system built with Go (backend) and React (frontend). It's based on One API and provides unified API access to multiple AI providers including OpenAI, Claude, Gemini, and many others.

## Development Commands

### Backend (Go)
- **Run development server**: `go run main.go`
- **Build**: `go build -o bin/new-api main.go`
- **Test**: `go test ./...`

### Frontend (React)
- **Install dependencies**: `cd web && bun install`
- **Development server**: `cd web && bun run dev`
- **Build**: `cd web && bun run build`
- **Lint**: `cd web && bun run lint`
- **Lint fix**: `cd web && bun run lint:fix`

### Full Stack Development
- **Build all**: `make all` (builds frontend and starts backend)
- **Frontend only**: `make build-frontend`
- **Backend only**: `make start-backend`

## Architecture

### Backend Structure
- **`main.go`**: Entry point, initializes services and starts HTTP server
- **`common/`**: Shared utilities, database, logging, Redis, constants
- **`model/`**: Database models and ORM operations
- **`controller/`**: HTTP handlers and API endpoints
- **`middleware/`**: HTTP middleware (auth, rate limiting, logging, etc.)
- **`router/`**: Route definitions and setup
- **`service/`**: Business logic and external service integrations
- **`relay/`**: AI provider adapters and request forwarding
- **`dto/`**: Data transfer objects
- **`constant/`**: Application constants
- **`setting/`**: Configuration management
- **`types/`**: Type definitions

### Frontend Structure
- **`web/src/`**: React application source
- **`web/src/components/`**: Reusable React components
- **`web/src/pages/`**: Page components
- **`web/src/context/`**: React context providers
- **`web/src/hooks/`**: Custom React hooks
- **`web/src/helpers/`**: Utility functions
- **`web/src/constants/`**: Frontend constants

### Key Features Architecture
- **Channel System**: Manages different AI provider connections (`relay/channel/`)
- **Token Management**: Handles API tokens and authentication
- **Rate Limiting**: Controls request rates per user/channel
- **Caching**: Redis-based caching for performance
- **Real-time Updates**: WebSocket support for live data
- **Multi-language Support**: i18n implementation

## Technology Stack

### Backend
- **Framework**: Gin (Go HTTP framework)
- **Database**: GORM with SQLite/MySQL/PostgreSQL support
- **Cache**: Redis
- **Session**: Cookie-based sessions
- **WebSocket**: Gorilla WebSocket

### Frontend
- **Framework**: React 18 with Vite
- **UI Library**: Semi UI (@douyinfe/semi-ui)
- **Styling**: Tailwind CSS
- **State Management**: React Context
- **Routing**: React Router DOM
- **Package Manager**: Bun

## Environment Setup

### Required Environment Variables
- `PORT`: Server port (default: 3000)
- `SQL_DSN`: Database connection string
- `REDIS_CONN_STRING`: Redis connection string
- `SESSION_SECRET`: Session encryption secret
- `CRYPTO_SECRET`: Data encryption secret

### Development Setup
1. Copy `.env.example` to `.env` and configure variables
2. Install Go dependencies: `go mod download`
3. Install frontend dependencies: `cd web && bun install`
4. Initialize database: Application will auto-migrate on first run
5. Start development: `make all`

## Key Patterns

### Adding New AI Providers
1. Create adapter in `relay/channel/[provider]/`
2. Implement required interface methods
3. Add provider constants
4. Register in channel factory

### Database Operations
- Use GORM models in `model/` directory
- Follow existing patterns for caching
- Use batch operations for performance

### API Endpoints
- Controllers in `controller/` handle HTTP requests
- Use middleware for common concerns
- Follow RESTful conventions
- Use DTOs for request/response structures

## Testing

- **Backend**: Use `go test ./...` to run all tests
- **Frontend**: Tests are configured but run via `bun test`
- **Integration**: Test channel connections via admin interface

## Deployment

- **Docker**: Use provided Dockerfile and docker-compose.yml
- **Binary**: Build with `go build` and deploy executable
- **Environment**: Supports SQLite (default) or external MySQL/PostgreSQL

## Important Notes

- Frontend uses Semi UI design system
- Backend supports multiple databases via GORM
- Redis is optional but recommended for production
- Session management uses secure cookies
- Rate limiting is implemented at multiple levels
- All AI provider integrations go through the relay system