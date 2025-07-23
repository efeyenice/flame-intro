import pool from '../config/database.js';

class Score {
  static async create(playerId, score) {
    const query = 'INSERT INTO scores (player_id, score) VALUES ($1, $2) RETURNING *';
    const values = [playerId, score];
    
    try {
      const result = await pool.query(query, values);
      const newScore = result.rows[0];
      
      // Get the rank of this score
      const rankQuery = `
        SELECT COUNT(*) + 1 as rank 
        FROM scores 
        WHERE score > $1
      `;
      const rankResult = await pool.query(rankQuery, [score]);
      
      return {
        ...newScore,
        rank: parseInt(rankResult.rows[0].rank)
      };
    } catch (error) {
      throw error;
    }
  }

  static async getLeaderboard(limit = 5) {
    const query = `
      SELECT 
        s.id,
        s.score,
        s.created_at as date,
        p.name as player_name,
        ROW_NUMBER() OVER (ORDER BY s.score DESC) as rank
      FROM scores s
      JOIN players p ON s.player_id = p.id
      ORDER BY s.score DESC
      LIMIT $1
    `;
    const values = [limit];
    
    try {
      const result = await pool.query(query, values);
      return result.rows.map(row => ({
        rank: parseInt(row.rank),
        playerName: row.player_name,
        score: row.score,
        date: row.date
      }));
    } catch (error) {
      throw error;
    }
  }

  static async getPlayerTopScore(playerId) {
    const query = `
      SELECT MAX(score) as top_score 
      FROM scores 
      WHERE player_id = $1
    `;
    const values = [playerId];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0].top_score || 0;
    } catch (error) {
      throw error;
    }
  }

  static async getPlayerScores(playerId) {
    const query = `
      SELECT * 
      FROM scores 
      WHERE player_id = $1 
      ORDER BY score DESC
    `;
    const values = [playerId];
    
    try {
      const result = await pool.query(query, values);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }
}

export default Score; 