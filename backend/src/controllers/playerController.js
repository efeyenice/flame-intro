import Player from '../models/Player.js';

export const createPlayer = async (req, res, next) => {
  try {
    const { name } = req.body;
    
    // Check if player already exists
    const existingPlayer = await Player.findByName(name);
    if (existingPlayer) {
      return res.status(200).json({
        id: existingPlayer.id,
        name: existingPlayer.name,
        message: 'Player already exists'
      });
    }
    
    // Create new player
    const newPlayer = await Player.create(name);
    
    res.status(201).json({
      id: newPlayer.id,
      name: newPlayer.name
    });
  } catch (error) {
    next(error);
  }
};

export const getPlayer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const playerId = parseInt(id);
    
    if (isNaN(playerId) || playerId <= 0) {
      return res.status(400).json({ error: 'Invalid player ID' });
    }
    
    const player = await Player.findById(playerId);
    
    if (!player) {
      return res.status(404).json({ error: 'Player not found' });
    }
    
    res.json({
      id: player.id,
      name: player.name,
      createdAt: player.created_at
    });
  } catch (error) {
    next(error);
  }
}; 