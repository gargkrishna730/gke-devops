#!/bin/sh
set -e

# Generate config.js with environment variables at runtime
cat > /usr/share/nginx/html/config.js << 'EOF'
window.ENV = {
  REACT_APP_BACKEND_URL: '${REACT_APP_BACKEND_URL:-http://localhost:3001}',
  REACT_APP_API_URL: '${REACT_APP_API_URL:-http://localhost:3001}'
};
EOF

# Start nginx
exec nginx -g "daemon off;"
