#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Notes App Setup & Installation${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create project structure
echo -e "${GREEN}Creating project structure...${NC}"
mkdir -p notes-app/{backend,frontend/src/{components,pages,services,styles,assets}}
cd notes-app

# ============================================
# BACKEND SETUP
# ============================================
echo -e "\n${GREEN}Setting up backend...${NC}"
cd backend

# Create package.json
cat > package.json << 'EOF'
{
  "name": "notes-backend",
  "version": "1.0.0",
  "description": "Notes API Backend",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "body-parser": "^1.20.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

# Create .env
cat > .env << 'EOF'
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=notes_db
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
const notesRoutes = require('./routes/notes');
app.use('/api/notes', notesRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
EOF

# Create database config
mkdir -p config
cat > config/database.js << 'EOF'
const mysql = require('mysql2');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const promisePool = pool.promise();

// Initialize database and table
const initDatabase = async () => {
  try {
    const connection = await promisePool.getConnection();

    // Create database if not exists
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME}`);
    await connection.query(`USE ${process.env.DB_NAME}`);

    // Create notes table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        category VARCHAR(50) DEFAULT 'General',
        color VARCHAR(20) DEFAULT '#6366f1',
        is_pinned BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    console.log('✅ Database initialized successfully');
    connection.release();
  } catch (error) {
    console.error('❌ Database initialization error:', error);
  }
};

initDatabase();

module.exports = promisePool;
EOF

# Create routes
mkdir -p routes
cat > routes/notes.js << 'EOF'
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
EOF

# Install backend dependencies
echo -e "${GREEN}Installing backend dependencies...${NC}"
npm install

# ============================================
# FRONTEND SETUP
# ============================================
echo -e "\n${GREEN}Setting up frontend...${NC}"
cd ../frontend

# Create package.json
cat > package.json << 'EOF'
{
  "name": "notes-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.1",
    "react-scripts": "5.0.1",
    "axios": "^1.6.2",
    "react-icons": "^4.12.0",
    "framer-motion": "^10.16.16"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF

# Create public/index.html
mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#6366f1" />
    <meta name="description" content="Modern Notes Application" />
    <title>Notes App - Your Digital Notebook</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

# Create src/index.js
cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# Create src/index.css
cat > src/index.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New', monospace;
}

::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
}

::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}
EOF

# Create src/App.js
cat > src/App.js << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import CreateNote from './pages/CreateNote';
import EditNote from './pages/EditNote';
import ViewNote from './pages/ViewNote';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/create" element={<CreateNote />} />
          <Route path="/edit/:id" element={<EditNote />} />
          <Route path="/view/:id" element={<ViewNote />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
EOF

# Create src/App.css
cat > src/App.css << 'EOF'
.App {
  min-height: 100vh;
  position: relative;
}
EOF

# Create API service
cat > src/services/api.js << 'EOF'
import axios from 'axios';

const API_URL = 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const notesAPI = {
  getAllNotes: () => api.get('/notes'),
  getNote: (id) => api.get(`/notes/${id}`),
  createNote: (data) => api.post('/notes', data),
  updateNote: (id, data) => api.put(`/notes/${id}`, data),
  deleteNote: (id) => api.delete(`/notes/${id}`),
  togglePin: (id) => api.patch(`/notes/${id}/pin`),
  searchNotes: (query) => api.get(`/notes/search/${query}`),
};

export default api;
EOF

# Create components
cat > src/components/Navbar.js << 'EOF'
import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FiPlus, FiHome, FiSearch } from 'react-icons/fi';
import { motion } from 'framer-motion';
import './Navbar.css';

const Navbar = ({ onSearch, searchQuery, setSearchQuery }) => {
  const navigate = useNavigate();

  return (
    <motion.nav
      className="navbar"
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          <motion.div
            className="logo-icon"
            whileHover={{ rotate: 360 }}
            transition={{ duration: 0.6 }}
          >
            📝
          </motion.div>
          <span>Notes</span>
        </Link>

        {onSearch && (
          <div className="search-bar">
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search notes..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                onSearch(e.target.value);
              }}
            />
          </div>
        )}

        <div className="navbar-actions">
          <motion.button
            className="nav-btn home-btn"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate('/')}
          >
            <FiHome />
            <span>Home</span>
          </motion.button>
          <motion.button
            className="nav-btn create-btn"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => navigate('/create')}
          >
            <FiPlus />
            <span>New Note</span>
          </motion.button>
        </div>
      </div>
    </motion.nav>
  );
};

export default Navbar;
EOF

cat > src/components/Navbar.css << 'EOF'
.navbar {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
  padding: 1rem 0;
  position: sticky;
  top: 0;
  z-index: 1000;
}

.navbar-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 2rem;
}

.navbar-logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  text-decoration: none;
  color: #6366f1;
  font-size: 1.5rem;
  font-weight: 800;
}

.logo-icon {
  font-size: 2rem;
}

.search-bar {
  flex: 1;
  max-width: 500px;
  position: relative;
}

.search-bar input {
  width: 100%;
  padding: 0.75rem 1rem 0.75rem 3rem;
  border: 2px solid #e5e7eb;
  border-radius: 50px;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.search-bar input:focus {
  outline: none;
  border-color: #6366f1;
  box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
}

.search-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
  font-size: 1.2rem;
}

.navbar-actions {
  display: flex;
  gap: 1rem;
}

.nav-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 50px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.home-btn {
  background: #f3f4f6;
  color: #4b5563;
}

.home-btn:hover {
  background: #e5e7eb;
}

.create-btn {
  background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
  color: white;
  box-shadow: 0 4px 15px rgba(99, 102, 241, 0.4);
}

.create-btn:hover {
  box-shadow: 0 6px 20px rgba(99, 102, 241, 0.6);
}

@media (max-width: 768px) {
  .navbar-container {
    flex-wrap: wrap;
    gap: 1rem;
  }

  .search-bar {
    order: 3;
    flex: 1 1 100%;
  }

  .nav-btn span {
    display: none;
  }
}
EOF

cat > src/components/NoteCard.js << 'EOF'
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiEye, FiPin } from 'react-icons/fi';
import { motion } from 'framer-motion';
import './NoteCard.css';

const NoteCard = ({ note, onDelete, onPin }) => {
  const navigate = useNavigate();

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <motion.div
      className="note-card"
      style={{ borderLeft: `4px solid ${note.color}` }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.9 }}
      whileHover={{ y: -5, boxShadow: '0 20px 40px rgba(0,0,0,0.15)' }}
      transition={{ duration: 0.3 }}
    >
      {note.is_pinned && (
        <div className="pin-badge">
          <FiPin /> Pinned
        </div>
      )}

      <div className="note-header">
        <motion.h3
          className="note-title"
          whileHover={{ color: note.color }}
        >
          {note.title}
        </motion.h3>
        <span className="note-category" style={{ backgroundColor: `${note.color}20`, color: note.color }}>
          {note.category}
        </span>
      </div>

      <p className="note-content">
        {note.content.length > 150 ? `${note.content.substring(0, 150)}...` : note.content}
      </p>

      <div className="note-footer">
        <span className="note-date">{formatDate(note.updated_at)}</span>

        <div className="note-actions">
          <motion.button
            className="action-btn view-btn"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate(`/view/${note.id}`)}
            title="View"
          >
            <FiEye />
          </motion.button>

          <motion.button
            className={`action-btn pin-btn ${note.is_pinned ? 'pinned' : ''}`}
            whileHover={{ scale: 1.1, rotate: 15 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => onPin(note.id)}
            title={note.is_pinned ? 'Unpin' : 'Pin'}
          >
            <FiPin />
          </motion.button>

          <motion.button
            className="action-btn edit-btn"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => navigate(`/edit/${note.id}`)}
            title="Edit"
          >
            <FiEdit2 />
          </motion.button>

          <motion.button
            className="action-btn delete-btn"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => onDelete(note.id)}
            title="Delete"
          >
            <FiTrash2 />
          </motion.button>
        </div>
      </div>
    </motion.div>
  );
};

export default NoteCard;
EOF

cat > src/components/NoteCard.css << 'EOF'
.note-card {
  background: white;
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.pin-badge {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: linear-gradient(135deg, #f59e0b 0%, #ef4444 100%);
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.note-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 1rem;
}

.note-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
  flex: 1;
  transition: color 0.3s ease;
}

.note-category {
  padding: 0.375rem 0.875rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  white-space: nowrap;
}

.note-content {
  color: #6b7280;
  line-height: 1.6;
  margin-bottom: 1.5rem;
  font-size: 0.95rem;
}

.note-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #f3f4f6;
}

.note-date {
  color: #9ca3af;
  font-size: 0.875rem;
}

.note-actions {
  display: flex;
  gap: 0.5rem;
}

.action-btn {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.view-btn {
  background: #eff6ff;
  color: #3b82f6;
}

.view-btn:hover {
  background: #3b82f6;
  color: white;
}

.pin-btn {
  background: #fef3c7;
  color: #f59e0b;
}

.pin-btn:hover {
  background: #f59e0b;
  color: white;
}

.pin-btn.pinned {
  background: #f59e0b;
  color: white;
}

.edit-btn {
  background: #f0fdf4;
  color: #22c55e;
}

.edit-btn:hover {
  background: #22c55e;
  color: white;
}

.delete-btn {
  background: #fef2f2;
  color: #ef4444;
}

.delete-btn:hover {
  background: #ef4444;
  color: white;
}
EOF

# Create pages
cat > src/pages/Home.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Navbar from '../components/Navbar';
import NoteCard from '../components/NoteCard';
import { notesAPI } from '../services/api';
import { FiInbox } from 'react-icons/fi';
import './Home.css';

const Home = () => {
  const [notes, setNotes] = useState([]);
  const [filteredNotes, setFilteredNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchNotes();
  }, []);

  const fetchNotes = async () => {
    try {
      const response = await notesAPI.getAllNotes();
      setNotes(response.data.data);
      setFilteredNotes(response.data.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching notes:', error);
      setLoading(false);
    }
  };

  const handleSearch = (query) => {
    if (!query.trim()) {
      setFilteredNotes(notes);
    } else {
      const filtered = notes.filter(note =>
        note.title.toLowerCase().includes(query.toLowerCase()) ||
        note.content.toLowerCase().includes(query.toLowerCase())
      );
      setFilteredNotes(filtered);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this note?')) {
      try {
        await notesAPI.deleteNote(id);
        fetchNotes();
      } catch (error) {
        console.error('Error deleting note:', error);
      }
    }
  };

  const handlePin = async (id) => {
    try {
      await notesAPI.togglePin(id);
      fetchNotes();
    } catch (error) {
      console.error('Error pinning note:', error);
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <motion.div
          className="loading-spinner"
          animate={{ rotate: 360 }}
          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
        >
          📝
        </motion.div>
      </div>
    );
  }

  return (
    <div className="home">
      <Navbar
        onSearch={handleSearch}
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
      />

      <div className="container">
        <motion.div
          className="header"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <h1>My Notes</h1>
          <p>Organize your thoughts, ideas, and memories</p>
        </motion.div>

        {filteredNotes.length === 0 ? (
          <motion.div
            className="empty-state"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
          >
            <FiInbox className="empty-icon" />
            <h2>{searchQuery ? 'No notes found' : 'No notes yet'}</h2>
            <p>{searchQuery ? 'Try a different search term' : 'Start creating your first note!'}</p>
          </motion.div>
        ) : (
          <motion.div
            className="notes-grid"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            <AnimatePresence>
              {filteredNotes.map((note) => (
                <NoteCard
                  key={note.id}
                  note={note}
                  onDelete={handleDelete}
                  onPin={handlePin}
                />
              ))}
            </AnimatePresence>
          </motion.div>
        )}
      </div>
    </div>
  );
};

export default Home;
EOF

cat > src/pages/Home.css << 'EOF'
.home {
  min-height: 100vh;
  padding-bottom: 4rem;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 3rem 2rem;
}

.header {
  text-align: center;
  margin-bottom: 3rem;
  color: white;
}

.header h1 {
  font-size: 3rem;
  font-weight: 800;
  margin-bottom: 0.5rem;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
}

.header p {
  font-size: 1.25rem;
  opacity: 0.95;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

.loading-spinner {
  font-size: 4rem;
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: white;
}

.empty-icon {
  font-size: 5rem;
  margin-bottom: 1.5rem;
  opacity: 0.8;
}

.empty-state h2 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.empty-state p {
  font-size: 1.125rem;
  opacity: 0.9;
}

.notes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 2rem;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 2rem;
  }

  .header p {
    font-size: 1rem;
  }

  .notes-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
}
EOF

cat > src/pages/CreateNote.js << 'EOF'
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import Navbar from '../components/Navbar';
import { notesAPI } from '../services/api';
import { FiSave, FiX } from 'react-icons/fi';
import './NoteForm.css';

const CreateNote = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    category: 'General',
    color: '#6366f1'
  });

  const colors = [
    '#6366f1', '#8b5cf6', '#ec4899', '#ef4444',
    '#f59e0b', '#10b981', '#06b6d4', '#6366f1'
  ];

  const categories = ['General', 'Work', 'Personal', 'Ideas', 'Todo', 'Important'];

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await notesAPI.createNote(formData);
      navigate('/');
    } catch (error) {
      console.error('Error creating note:', error);
      alert('Failed to create note');
    }
  };

  return (
    <div className="note-form-page">
      <Navbar />

      <div className="form-container">
        <motion.div
          className="form-card"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div className="form-header">
            <h1>Create New Note</h1>
            <motion.button
              className="close-btn"
              whileHover={{ scale: 1.1, rotate: 90 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => navigate('/')}
            >
              <FiX />
            </motion.button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Title</label>
              <input
                type="text"
                placeholder="Enter note title..."
                value={formData.title}
                onChange={(e) => setFormData({...formData, title: e.target.value})}
                required
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Category</label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({...formData, category: e.target.value})}
                >
                  {categories.map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Color</label>
                <div className="color-picker">
                  {colors.map(color => (
                    <motion.button
                      key={color}
                      type="button"
                      className={`color-option ${formData.color === color ? 'active' : ''}`}
                      style={{ backgroundColor: color }}
                      onClick={() => setFormData({...formData, color})}
                      whileHover={{ scale: 1.2 }}
                      whileTap={{ scale: 0.9 }}
                    />
                  ))}
                </div>
              </div>
            </div>

            <div className="form-group">
              <label>Content</label>
              <textarea
                placeholder="Write your note here..."
                value={formData.content}
                onChange={(e) => setFormData({...formData, content: e.target.value})}
                rows="12"
                required
              />
            </div>

            <div className="form-actions">
              <motion.button
                type="button"
                className="btn btn-secondary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate('/')}
              >
                Cancel
              </motion.button>
              <motion.button
                type="submit"
                className="btn btn-primary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <FiSave />
                Save Note
              </motion.button>
            </div>
          </form>
        </motion.div>
      </div>
    </div>
  );
};

export default CreateNote;
EOF

cat > src/pages/EditNote.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import Navbar from '../components/Navbar';
import { notesAPI } from '../services/api';
import { FiSave, FiX } from 'react-icons/fi';
import './NoteForm.css';

const EditNote = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    category: 'General',
    color: '#6366f1',
    is_pinned: false
  });
  const [loading, setLoading] = useState(true);

  const colors = [
    '#6366f1', '#8b5cf6', '#ec4899', '#ef4444',
    '#f59e0b', '#10b981', '#06b6d4', '#6366f1'
  ];

  const categories = ['General', 'Work', 'Personal', 'Ideas', 'Todo', 'Important'];

  useEffect(() => {
    fetchNote();
  }, [id]);

  const fetchNote = async () => {
    try {
      const response = await notesAPI.getNote(id);
      setFormData(response.data.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching note:', error);
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await notesAPI.updateNote(id, formData);
      navigate('/');
    } catch (error) {
      console.error('Error updating note:', error);
      alert('Failed to update note');
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <motion.div
          className="loading-spinner"
          animate={{ rotate: 360 }}
          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
        >
          📝
        </motion.div>
      </div>
    );
  }

  return (
    <div className="note-form-page">
      <Navbar />

      <div className="form-container">
        <motion.div
          className="form-card"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div className="form-header">
            <h1>Edit Note</h1>
            <motion.button
              className="close-btn"
              whileHover={{ scale: 1.1, rotate: 90 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => navigate('/')}
            >
              <FiX />
            </motion.button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Title</label>
              <input
                type="text"
                placeholder="Enter note title..."
                value={formData.title}
                onChange={(e) => setFormData({...formData, title: e.target.value})}
                required
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Category</label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({...formData, category: e.target.value})}
                >
                  {categories.map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Color</label>
                <div className="color-picker">
                  {colors.map(color => (
                    <motion.button
                      key={color}
                      type="button"
                      className={`color-option ${formData.color === color ? 'active' : ''}`}
                      style={{ backgroundColor: color }}
                      onClick={() => setFormData({...formData, color})}
                      whileHover={{ scale: 1.2 }}
                      whileTap={{ scale: 0.9 }}
                    />
                  ))}
                </div>
              </div>
            </div>

            <div className="form-group">
              <label>Content</label>
              <textarea
                placeholder="Write your note here..."
                value={formData.content}
                onChange={(e) => setFormData({...formData, content: e.target.value})}
                rows="12"
                required
              />
            </div>

            <div className="form-actions">
              <motion.button
                type="button"
                className="btn btn-secondary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate('/')}
              >
                Cancel
              </motion.button>
              <motion.button
                type="submit"
                className="btn btn-primary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <FiSave />
                Update Note
              </motion.button>
            </div>
          </form>
        </motion.div>
      </div>
    </div>
  );
};

export default EditNote;
EOF

cat > src/pages/ViewNote.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import Navbar from '../components/Navbar';
import { notesAPI } from '../services/api';
import { FiEdit2, FiTrash2, FiArrowLeft, FiPin } from 'react-icons/fi';
import './ViewNote.css';

const ViewNote = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [note, setNote] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchNote();
  }, [id]);

  const fetchNote = async () => {
    try {
      const response = await notesAPI.getNote(id);
      setNote(response.data.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching note:', error);
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this note?')) {
      try {
        await notesAPI.deleteNote(id);
        navigate('/');
      } catch (error) {
        console.error('Error deleting note:', error);
      }
    }
  };

  const handlePin = async () => {
    try {
      await notesAPI.togglePin(id);
      fetchNote();
    } catch (error) {
      console.error('Error pinning note:', error);
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="loading-container">
        <motion.div
          className="loading-spinner"
          animate={{ rotate: 360 }}
          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
        >
          📝
        </motion.div>
      </div>
    );
  }

  if (!note) {
    return (
      <div className="note-form-page">
        <Navbar />
        <div className="form-container">
          <div className="error-message">Note not found</div>
        </div>
      </div>
    );
  }

  return (
    <div className="note-form-page">
      <Navbar />

      <div className="form-container">
        <motion.div
          className="view-card"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          style={{ borderTop: `4px solid ${note.color}` }}
        >
          <div className="view-header">
            <motion.button
              className="back-btn"
              whileHover={{ scale: 1.05, x: -5 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => navigate('/')}
            >
              <FiArrowLeft /> Back
            </motion.button>

            <div className="view-actions">
              <motion.button
                className={`action-btn-large pin-btn ${note.is_pinned ? 'pinned' : ''}`}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handlePin}
              >
                <FiPin /> {note.is_pinned ? 'Unpin' : 'Pin'}
              </motion.button>

              <motion.button
                className="action-btn-large edit-btn"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate(`/edit/${note.id}`)}
              >
                <FiEdit2 /> Edit
              </motion.button>

              <motion.button
                className="action-btn-large delete-btn"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleDelete}
              >
                <FiTrash2 /> Delete
              </motion.button>
            </div>
          </div>

          <div className="view-content">
            <div className="view-meta">
              <span
                className="view-category"
                style={{ backgroundColor: `${note.color}20`, color: note.color }}
              >
                {note.category}
              </span>
              <span className="view-date">{formatDate(note.updated_at)}</span>
            </div>

            <h1 className="view-title">{note.title}</h1>

            <div className="view-text">
              {note.content.split('\n').map((paragraph, index) => (
                <p key={index}>{paragraph}</p>
              ))}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default ViewNote;
EOF

cat > src/pages/NoteForm.css << 'EOF'
.note-form-page {
  min-height: 100vh;
  padding-bottom: 4rem;
}

.form-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 3rem 2rem;
}

.form-card {
  background: white;
  border-radius: 20px;
  padding: 2.5rem;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
}

.form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.form-header h1 {
  font-size: 2rem;
  color: #1f2937;
  font-weight: 800;
}

.close-btn {
  width: 40px;
  height: 40px;
  border: none;
  background: #f3f4f6;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1.5rem;
  color: #6b7280;
  transition: all 0.3s ease;
}

.close-btn:hover {
  background: #ef4444;
  color: white;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #374151;
  font-size: 0.95rem;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.875rem 1rem;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-size: 1rem;
  font-family: inherit;
  transition: all 0.3s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #6366f1;
  box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
}

.form-group textarea {
  resize: vertical;
  line-height: 1.6;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.color-picker {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.color-option {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 3px solid transparent;
  cursor: pointer;
  transition: all 0.3s ease;
}

.color-option.active {
  border-color: white;
  box-shadow: 0 0 0 2px currentColor;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #e5e7eb;
}

.btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 2rem;
  border: none;
  border-radius: 50px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
  color: white;
  box-shadow: 0 4px 15px rgba(99, 102, 241, 0.4);
}

.btn-primary:hover {
  box-shadow: 0 6px 20px rgba(99, 102, 241, 0.6);
}

.btn-secondary {
  background: #f3f4f6;
  color: #4b5563;
}

.btn-secondary:hover {
  background: #e5e7eb;
}

@media (max-width: 768px) {
  .form-card {
    padding: 1.5rem;
  }

  .form-header h1 {
    font-size: 1.5rem;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .form-actions {
    flex-direction: column-reverse;
  }

  .btn {
    width: 100%;
    justify-content: center;
  }
}
EOF

cat > src/pages/ViewNote.css << 'EOF'
.view-card {
  background: white;
  border-radius: 20px;
  overflow: hidden;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
}

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 2rem 2.5rem;
  border-bottom: 1px solid #f3f4f6;
  background: #fafafa;
}

.back-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  background: white;
  border-radius: 50px;
  font-size: 1rem;
  font-weight: 600;
  color: #4b5563;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.back-btn:hover {
  background: #f3f4f6;
}

.view-actions {
  display: flex;
  gap: 0.75rem;
}

.action-btn-large {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  border: none;
  border-radius: 50px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.action-btn-large.pin-btn {
  background: #fef3c7;
  color: #f59e0b;
}

.action-btn-large.pin-btn:hover {
  background: #fde68a;
}

.action-btn-large.pin-btn.pinned {
  background: #f59e0b;
  color: white;
}

.action-btn-large.edit-btn {
  background: #dbeafe;
  color: #3b82f6;
}

.action-btn-large.edit-btn:hover {
  background: #bfdbfe;
}

.action-btn-large.delete-btn {
  background: #fee2e2;
  color: #ef4444;
}

.action-btn-large.delete-btn:hover {
  background: #fecaca;
}

.view-content {
  padding: 2.5rem;
}

.view-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.view-category {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 600;
}

.view-date {
  color: #9ca3af;
  font-size: 0.95rem;
}

.view-title {
  font-size: 2.5rem;
  font-weight: 800;
  color: #1f2937;
  margin-bottom: 2rem;
  line-height: 1.2;
}

.view-text {
  font-size: 1.125rem;
  line-height: 1.8;
  color: #4b5563;
}

.view-text p {
  margin-bottom: 1rem;
}

.error-message {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 20px;
  color: #ef4444;
  font-size: 1.25rem;
  font-weight: 600;
}

@media (max-width: 768px) {
  .view-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }

  .view-actions {
    justify-content: stretch;
  }

  .action-btn-large {
    flex: 1;
    justify-content: center;
  }

  .view-content {
    padding: 1.5rem;
  }

  .view-title {
    font-size: 1.75rem;
  }

  .view-text {
    font-size: 1rem;
  }
}
EOF

# Install frontend dependencies
echo -e "${GREEN}Installing frontend dependencies...${NC}"
npm install

# Go back to root
cd ..

# Create README
cat > README.md << 'EOF'
# Notes Application

A professional full-stack CRUD notes application with a beautiful, animated UI.

## Features

- ✨ Create, Read, Update, Delete notes
- 📌 Pin important no- 🎨 Color-coded categories
- 🔍 Search functionality
- 📱 Responsive design
- 🎭 Smooth animations
- 💾 MySQL database

## Tech Stack

**Frontend:**
- React.js
- Framer Motion (animations)
- React Router (routing)
- Axios (API calls)

**Backend:**
- Node.js
- Express.js
- MySQL2

## Setup Instructions

1. Make sure MySQL is installed and running
2. Update database credentials in `backend/.env`
3. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

## Manual Setup

If you p set up manually:

### Backend
```bash
cd backend
npm install
# Update .env with your MySQL credentials
npm start
```

### Frontend
```bash
cd frontend
npm install
npm start
```

## Default Configuration

- Backend runs on: http://localhost:5000
- Frontend runs on: http://localhost:3000
- Database name: notes_db

## Database Configuration

Update the following in `backend/.env`:
- DB_HOST=localhost
- DB_USER=root
- DB_PASSWORD=your_password
- DB_NAME=notes_db

The database and table will be created automatically when you start the backend.

## API Endpoints

- GET /api/notes - Get all notes
- GET /api/notes/:id - Get single note
- POST /api/notes - Create note
- PUT /api/notes/:id - Update note
- DELETE /api/notes/:id - Delete note
- PATCH /api/notes/:id/pin - Toggle pin status
- GET /api/notes/search/:query - Search notes

## Author

Built with ❤️ using React, Node.js, and MySQL
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -eGREEN}========================================${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Update MySQL credentials in: ${BLUE}backend/.env${NC}"
echo -e "2. Start the backend: ${BLUE}cd backend && npm start${NC}"
echo -e "3. Start the frontend: ${BLUE}cd frontend && npm start${NC}\n"

echo -e "${GREEN}The application will be available at:${NC}"
echo -e "Frontend: ${BLUE}http://localhost:3000${NC}"
echo -e "Backend:  ${BLUE}http://localhost:5000${NC}\n"

echo -e "${YELLOW}Note: Make sure MySQL is running before starting the backend!${NC}\n"
