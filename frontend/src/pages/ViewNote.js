import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import Navbar from '../components/Navbar';
import { notesAPI } from '../services/api';
import { FiEdit2, FiTrash2, FiArrowLeft, FiMapPin } from 'react-icons/fi';
import './ViewNote.css';

const ViewNote = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [note, setNote] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
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
    fetchNote();
  }, [id]);

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
      // re-fetch note after pin toggle
      const response = await notesAPI.getNote(id);
      setNote(response.data.data);
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
                <FiMapPin /> {note.is_pinned ? 'Unpin' : 'Pin'}
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

