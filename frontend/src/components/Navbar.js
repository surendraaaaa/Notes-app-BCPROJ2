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
