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

  fetchNote();
}, [id]);


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
