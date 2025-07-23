-- Drop existing tables if they exist
DROP TABLE IF EXISTS scores CASCADE;
DROP TABLE IF EXISTS players CASCADE;

-- Create players table
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create scores table
CREATE TABLE scores (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id),
    score INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for efficient leaderboard queries
CREATE INDEX idx_scores_score_desc ON scores(score DESC);

-- Optional: Add some initial test data
-- INSERT INTO players (name) VALUES ('Test Player 1'), ('Test Player 2');
-- INSERT INTO scores (player_id, score) VALUES (1, 1000), (2, 1500), (1, 2000); 