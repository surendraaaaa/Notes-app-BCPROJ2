import axios from 'axios';

// Relative path, backend will be proxied
const API_URL = '/api';

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
