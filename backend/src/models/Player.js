import pool from '../config/database.js';

class Player {
  static async create(name) {
    const query = 'INSERT INTO players (name) VALUES ($1) RETURNING *';
    const values = [name];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }

  static async findById(id) {
    const query = 'SELECT * FROM players WHERE id = $1';
    const values = [id];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }

  static async findByName(name) {
    const query = 'SELECT * FROM players WHERE name = $1';
    const values = [name];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }
}

export default Player; 