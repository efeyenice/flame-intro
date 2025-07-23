# Multicontainer Leaderboard Implementation Plan

## Overview
Convert the existing Flutter Flame brick breaker game into a multicontainer application with persistent leaderboard functionality.

## Architecture
```
┌─────────────────┐     HTTP/JSON      ┌─────────────────┐
│   Flutter Game  │ ◄─────────────────► │   Backend API   │
│   (Container 1) │                     │   (Container 2) │
│   Port: 3000    │                     │   Port: 8000    │
└─────────────────┘                     └─────────────────┘
                                                 │
                                                 ▼
                                        ┌─────────────────┐
                                        │   PostgreSQL    │
                                        │   (Container 3) │
                                        │   Port: 5432    │
                                        └─────────────────┘
```

## Implementation Steps

### Phase 1: Backend Development
- [x] Create backend project structure with Node.js and Express
- [x] Set up PostgreSQL database schema for players and scores
- [x] Implement API endpoints:
  - `POST /api/players` - Create player session
  - `POST /api/scores` - Submit score
  - `GET /api/leaderboard` - Get top 5 scores
  - `GET /api/health` - Health check endpoint
- [x] Add CORS configuration for Flutter web
- [x] Implement input validation and error handling

### Phase 2: Frontend Modifications
- [x] Add player name input screen before game starts
- [x] Create LeaderboardService class for API communication
- [x] Implement leaderboard display screen with top 5 scores
- [x] Integrate score submission on game over
- [x] Add navigation between game states and leaderboard
- [x] Handle offline/error states gracefully

### Phase 3: Containerization
- [x] Create backend Dockerfile
- [x] Update game Dockerfile for environment configuration
- [x] Create docker-compose.yml for local development
- [x] Create docker-compose.prod.yml for production
- [x] Configure environment variables for API URLs

### Phase 4: CI/CD Updates
- [ ] Update GitHub Actions to build multicontainer setup
- [ ] Configure Docker Hub for backend image
- [ ] Update deployment scripts for Azure
- [ ] Add database migration handling

## Technical Specifications

### Database Schema
```sql
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scores (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id),
    score INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scores_score_desc ON scores(score DESC);
```

### API Endpoints

#### POST /api/players
Request:
```json
{
  "name": "Player Name"
}
```
Response:
```json
{
  "id": 1,
  "name": "Player Name"
}
```

#### POST /api/scores
Request:
```json
{
  "playerId": 1,
  "score": 1500
}
```
Response:
```json
{
  "id": 1,
  "playerId": 1,
  "score": 1500,
  "rank": 3
}
```

#### GET /api/leaderboard
Response:
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "playerName": "Alice",
      "score": 2500,
      "date": "2024-01-15T10:30:00Z"
    },
    // ... top 5 entries
  ]
}
```

## Environment Variables

### Game Container
- `API_URL`: Backend API URL (default: http://localhost:8000)

### Backend Container
- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: API server port (default: 8000)
- `CORS_ORIGIN`: Allowed origins for CORS

### Database Container
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password

## Success Criteria
- [ ] Players can enter their name before starting the game
- [ ] Scores are automatically submitted on game over
- [ ] Leaderboard displays top 5 scores
- [ ] All containers communicate properly
- [ ] Deployment works on Azure with persistent data
- [ ] Game remains playable offline (graceful degradation) 