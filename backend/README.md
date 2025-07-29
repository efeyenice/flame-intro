# Brick Breaker Leaderboard API

Backend API for the Flame Intro Brick Breaker game, providing player management and leaderboard functionality.

## Setup

### Prerequisites
- Node.js 22+ (upgraded for security fixes including CVE-2024-21538)
- PostgreSQL 13+
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create a PostgreSQL database:
```bash
createdb gamedb
```

3. Run the database schema:
```bash
psql -d gamedb -f database/schema.sql
```

4. Create a `.env` file with your configuration:
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/gamedb
PORT=8000
CORS_ORIGIN=http://localhost:3000
NODE_ENV=development
```

### Running the Server

Development mode with auto-reload:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## API Endpoints

### Health Check
- `GET /api/health` - Check server status

### Players
- `POST /api/players` - Create a new player
  ```json
  {
    "name": "Player Name"
  }
  ```
- `GET /api/players/:id` - Get player details

### Scores
- `POST /api/scores` - Submit a score
  ```json
  {
    "playerId": 1,
    "score": 1500
  }
  ```
- `GET /api/players/:playerId/scores` - Get all scores for a player

### Leaderboard
- `GET /api/leaderboard?limit=5` - Get top scores (default: 5)

## Project Structure

```
backend/
├── src/
│   ├── config/        # Database configuration
│   ├── controllers/   # Request handlers
│   ├── middleware/    # Express middleware
│   ├── models/        # Database models
│   ├── routes/        # API routes
│   └── index.js       # Main server file
├── database/
│   └── schema.sql     # Database schema
├── package.json
└── README.md
```

## Testing

You can test the API using curl:

```bash
# Create a player
curl -X POST http://localhost:8000/api/players \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Player"}'

# Submit a score
curl -X POST http://localhost:8000/api/scores \
  -H "Content-Type: application/json" \
  -d '{"playerId": 1, "score": 1000}'

# Get leaderboard
curl http://localhost:8000/api/leaderboard
``` 