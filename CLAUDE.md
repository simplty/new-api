# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

New API is a next-generation AI model gateway and asset management system built in Go, based on the One API project. It provides a unified API interface for multiple AI model providers (OpenAI, Claude, Gemini, etc.) with features like model management, user authentication, quota tracking, and web dashboard.

## Development Commands

### Backend (Go)
- `go run main.go` - Start the backend server (default port 3000)
- `go build` - Build the backend binary
- `go mod tidy` - Clean up Go module dependencies

### Frontend (React with Vite)
- `cd web && bun install` - Install frontend dependencies
- `cd web && bun run dev` - Start frontend development server
- `cd web && bun run build` - Build frontend for production
- `cd web && bun run lint` - Check code formatting
- `cd web && bun run lint:fix` - Fix code formatting issues

### Combined Development
- `make all` - Build frontend and start backend (uses Makefile)
- `make build-frontend` - Build frontend only
- `make start-backend` - Start backend only

## Architecture Overview

### Core Components

1. **Main Application** (`main.go`):
   - Application entry point
   - Initializes resources, database, Redis, and HTTP server
   - Handles embedded web assets (`web/dist`)

2. **Database Layer** (`model/`):
   - GORM-based ORM with support for SQLite, MySQL, PostgreSQL
   - Separate log database support via `LOG_SQL_DSN`
   - Models include: User, Channel, Token, Log, Midjourney, Task, etc.

3. **API Gateway & Relay** (`relay/`):
   - Adapter pattern for different AI providers
   - Channel-specific implementations in `relay/channel/`
   - Request routing, response handling, and format conversion

4. **Routing** (`router/`):
   - API routes (`api-router.go`)
   - Relay routes (`relay-router.go`) 
   - Dashboard routes (`dashboard.go`)
   - Web routes (`web-router.go`)

5. **Controllers** (`controller/`):
   - Business logic for channels, users, tokens, billing, etc.
   - Channel testing and management
   - Midjourney and task processing

6. **Middleware** (`middleware/`):
   - Authentication, rate limiting, CORS, logging
   - Model-specific rate limiting
   - Request ID and stats collection

7. **Frontend** (`web/`):
   - React application with Semi-UI components
   - Vite build system with TypeScript
   - Playground for API testing
   - Management dashboards

### Key Patterns

- **Adapter Pattern**: Each AI provider has its own adapter in `relay/channel/`
- **Channel System**: Unified interface for different AI model providers
- **Token Management**: API key management with usage tracking
- **Quota System**: User and token-based quota management
- **Caching**: Redis-based caching with fallback to memory cache

## Environment Variables

Key environment variables for development:
- `DEBUG=true` - Enable debug mode
- `GIN_MODE=debug` - Gin debug mode
- `SQL_DSN` - Database connection string
- `LOG_SQL_DSN` - Separate log database (optional)
- `REDIS_CONN_STRING` - Redis connection for caching
- `SESSION_SECRET` - Session encryption secret
- `CRYPTO_SECRET` - Data encryption secret
- `PORT` - Server port (default: 3000)

## Database

The application supports multiple database backends:
- **SQLite** (default): Local file-based database
- **MySQL**: Remote MySQL database (version >= 5.7.8)
- **PostgreSQL**: Remote PostgreSQL database (version >= 9.6)

Database migrations are handled automatically on startup via GORM AutoMigrate.

## Testing

The project currently doesn't have a comprehensive test suite. Tests should be added to the `test/` directory as per the global instructions.

## Key Files to Understand

- `main.go` - Application entry point and initialization
- `model/main.go` - Database setup and migration
- `relay/relay_adaptor.go` - AI provider adapter registry
- `router/main.go` - Route configuration
- `common/init.go` - Environment variable setup
- `web/src/App.js` - Frontend application root

## Development Tips

- The project uses embedded file system for frontend assets
- Channel implementations follow a consistent adapter pattern
- Database schemas are defined using GORM struct tags
- All user-facing messages support internationalization
- The system supports both master/slave node deployment

## 对话行为规范

- 在对话过程中,对代码有改动,将所有的改动都记录到一个"自定义功能文档"中

## 文档管理规范

- 自定义功能文档 应该是一个独立的文件