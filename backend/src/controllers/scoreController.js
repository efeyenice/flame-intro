import Score from '../models/Score.js';
import Player from '../models/Player.js';

export const submitScore = async (req, res, next) => {
  try {
    const { playerId, score } = req.body;
    
    // Verify player exists
    const player = await Player.findById(playerId);
    if (!player) {
      return res.status(404).json({ error: 'Player not found' });
    }
    
    // Create score entry
    const scoreEntry = await Score.create(playerId, score);
    
    res.status(201).json({
      id: scoreEntry.id,
      playerId: scoreEntry.player_id,
      score: scoreEntry.score,
      rank: scoreEntry.rank
    });
  } catch (error) {
    next(error);
  }
};

export const getLeaderboard = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 5;
    
    if (limit < 1 || limit > 100) {
      return res.status(400).json({ 
        error: 'Limit must be between 1 and 100' 
      });
    }
    
    const leaderboard = await Score.getLeaderboard(limit);
    
    res.json({
      leaderboard
    });
  } catch (error) {
    next(error);
  }
};

export const getPlayerScores = async (req, res, next) => {
  try {
    const { playerId } = req.params;
    const id = parseInt(playerId);
    
    if (isNaN(id) || id <= 0) {
      return res.status(400).json({ error: 'Invalid player ID' });
    }
    
    // Verify player exists
    const player = await Player.findById(id);
    if (!player) {
      return res.status(404).json({ error: 'Player not found' });
    }
    
    const scores = await Score.getPlayerScores(id);
    const topScore = await Score.getPlayerTopScore(id);
    
    res.json({
      playerId: id,
      playerName: player.name,
      topScore,
      scores: scores.map(s => ({
        id: s.id,
        score: s.score,
        date: s.created_at
      }))
    });
  } catch (error) {
    next(error);
  }
}; 