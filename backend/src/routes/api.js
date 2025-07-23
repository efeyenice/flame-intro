import express from 'express';
import { createPlayer, getPlayer } from '../controllers/playerController.js';
import { submitScore, getLeaderboard, getPlayerScores } from '../controllers/scoreController.js';
import { validatePlayerName, validateScore } from '../middleware/validation.js';

const router = express.Router();

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// Player endpoints
router.post('/players', validatePlayerName, createPlayer);
router.get('/players/:id', getPlayer);

// Score endpoints
router.post('/scores', validateScore, submitScore);
router.get('/players/:playerId/scores', getPlayerScores);

// Leaderboard endpoint
router.get('/leaderboard', getLeaderboard);

export default router; 