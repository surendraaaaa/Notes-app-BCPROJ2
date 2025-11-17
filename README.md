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
