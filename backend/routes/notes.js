const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Get all notes
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM notes ORDER BY is_pinned DESC, updated_at DESC'
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get single note
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM notes WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }
    res.json({ success: true, data: rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Create note
router.post('/', async (req, res) => {
  try {
    const { title, content, category, color } = req.body;
    const [result] = await db.query(
      'INSERT INTO notes (title, content, category, color) VALUES (?, ?, ?, ?)',
      [title, content, category || 'General', color || '#6366f1']
    );
    const [newNote] = await db.query('SELECT * FROM notes WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: newNote[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update note
router.put('/:id', async (req, res) => {
  try {
    const { title, content, category, color, is_pinned } = req.body;
    await db.query(
      'UPDATE notes SET title = ?, content = ?, category = ?, color = ?, is_pinned = ? WHERE id = ?',
      [title, content, category, color, is_pinned, req.params.id]
    );
    const [updatedNote] = await db.query('SELECT * FROM notes WHERE id = ?', [req.params.id]);
    res.json({ success: true, data: updatedNote[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Toggle pin
router.patch('/:id/pin', async (req, res) => {
  try {
    const [note] = await db.query('SELECT is_pinned FROM notes WHERE id = ?', [req.params.id]);
    const newPinStatus = !note[0].is_pinned;
    await db.query('UPDATE notes SET is_pinned = ? WHERE id = ?', [newPinStatus, req.params.id]);
    const [updatedNote] = await db.query('SELECT * FROM notes WHERE id = ?', [req.params.id]);
    res.json({ success: true, data: updatedNote[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Delete note
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM notes WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Note deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Search notes
router.get('/search/:query', async (req, res) => {
  try {
    const searchQuery = `%${req.params.query}%`;
    const [rows] = await db.query(
      'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY is_pinned DESC, updated_at DESC',
      [searchQuery, searchQuery]
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
