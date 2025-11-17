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
