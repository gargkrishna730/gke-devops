import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [data, setData] = useState(null);
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState('');

  const backendUrl = process.env.REACT_APP_BACKEND_URL || 'http://localhost:3001';

  useEffect(() => {
    fetchStatus();
  }, []);

  const fetchStatus = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${backendUrl}/api/v1/status`);
      setStatus(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch backend status');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchData = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${backendUrl}/api/v1/data`);
      setData(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch data from backend');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const sendEcho = async (e) => {
    e.preventDefault();
    if (!message.trim()) return;

    try {
      setLoading(true);
      const response = await axios.post(`${backendUrl}/api/v1/echo`, {
        message: message
      });
      setData(response.data);
      setMessage('');
      setError(null);
    } catch (err) {
      setError('Failed to send message to backend');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <header className="header">
        <h1>✨ CloudSync Dashboard</h1>
        <p>Real-time Service Monitoring & Communication</p>
      </header>

      <main className="main">
        {/* Status Card */}
        <section className="card">
          <h2>📊 Service Status</h2>
          {status ? (
            <div className="status-info">
              <p><strong>Service:</strong> {status.service}</p>
              <p><strong>Version:</strong> {status.version}</p>
              <p><strong>Environment:</strong> {status.environment}</p>
              <p><strong>Uptime:</strong> {status.uptime.toFixed(2)}s</p>
              <div className="status-badge">✓ Connected</div>
            </div>
          ) : (
            <p>Loading status...</p>
          )}
          <button onClick={fetchStatus} disabled={loading} className="btn btn-primary">
            Refresh Status
          </button>
        </section>

        {/* Data Fetching Card */}
        <section className="card">
          <h2>📈 Live Data Feed</h2>
          <button onClick={fetchData} disabled={loading} className="btn btn-secondary">
            {loading ? 'Loading...' : 'Fetch Data'}
          </button>
          {data && (
            <div className="data-display">
              <p><strong>Message:</strong> {data.message}</p>
              <div className="data-list">
                {data.data && data.data.map((item) => (
                  <div key={item.id} className="data-item">
                    <strong>{item.name}</strong>
                    <p>{item.description}</p>
                  </div>
                ))}
              </div>
              <small>Timestamp: {new Date(data.timestamp).toLocaleString()}</small>
            </div>
          )}
        </section>

        {/* Echo Message Card */}
        <section className="card">
          <h2>💬 Send Message</h2>
          <form onSubmit={sendEcho} className="echo-form">
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Enter a message..."
              disabled={loading}
              className="input"
            />
            <button type="submit" disabled={loading} className="btn btn-success">
              {loading ? 'Sending...' : 'Send'}
            </button>
          </form>
          {data && data.echoed && (
            <div className="echo-response">
              <p><strong>Received:</strong> {data.received}</p>
              <p><strong>Echoed:</strong> {data.echoed}</p>
            </div>
          )}
        </section>

        {/* Error Display */}
        {error && (
          <section className="card error-card">
            <h3>⚠️ Error</h3>
            <p>{error}</p>
          </section>
        )}
      </main>

      <footer className="footer">
        <p>© 2025 CloudSync. All rights reserved.</p>
      </footer>
    </div>
  );
}

export default App;
