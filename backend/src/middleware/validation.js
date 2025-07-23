// Validation middleware for API endpoints

export const validatePlayerName = (req, res, next) => {
  const { name } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Player name is required' });
  }
  
  if (typeof name !== 'string') {
    return res.status(400).json({ error: 'Player name must be a string' });
  }
  
  const trimmedName = name.trim();
  
  if (trimmedName.length === 0) {
    return res.status(400).json({ error: 'Player name cannot be empty' });
  }
  
  if (trimmedName.length > 50) {
    return res.status(400).json({ error: 'Player name must be 50 characters or less' });
  }
  
  // Only allow alphanumeric characters, spaces, and some special characters
  const nameRegex = /^[a-zA-Z0-9\s\-_.]+$/;
  if (!nameRegex.test(trimmedName)) {
    return res.status(400).json({ 
      error: 'Player name can only contain letters, numbers, spaces, hyphens, underscores, and periods' 
    });
  }
  
  // Sanitize the name and attach to request
  req.body.name = trimmedName;
  next();
};

export const validateScore = (req, res, next) => {
  const { playerId, score } = req.body;
  
  if (!playerId) {
    return res.status(400).json({ error: 'Player ID is required' });
  }
  
  if (!score && score !== 0) {
    return res.status(400).json({ error: 'Score is required' });
  }
  
  const playerIdNum = parseInt(playerId);
  const scoreNum = parseInt(score);
  
  if (isNaN(playerIdNum) || playerIdNum <= 0) {
    return res.status(400).json({ error: 'Invalid player ID' });
  }
  
  if (isNaN(scoreNum) || scoreNum < 0) {
    return res.status(400).json({ error: 'Score must be a non-negative number' });
  }
  
  // Maximum reasonable score limit (prevent overflow)
  if (scoreNum > 999999) {
    return res.status(400).json({ error: 'Score value is too high' });
  }
  
  req.body.playerId = playerIdNum;
  req.body.score = scoreNum;
  next();
};

export const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // Database connection errors
  if (err.code === 'ECONNREFUSED') {
    return res.status(503).json({ 
      error: 'Database connection failed. Please try again later.' 
    });
  }
  
  // Foreign key constraint errors
  if (err.code === '23503') {
    return res.status(400).json({ 
      error: 'Invalid player ID' 
    });
  }
  
  // Default error response
  res.status(500).json({ 
    error: 'An unexpected error occurred. Please try again later.' 
  });
}; 