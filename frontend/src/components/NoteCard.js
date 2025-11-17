import React from 'react';
import { useNavigate } from 'react-router-dom';
import { FiEdit2, FiTrash2, FiEye, FiMapPin } from 'react-icons/fi';
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
          <FiMapPin /> Pinned
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
            <FiMapPin />
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
