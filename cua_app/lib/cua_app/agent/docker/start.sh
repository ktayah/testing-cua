#!/bin/bash
# Start Xvfb
Xvfb :99 -screen 0 ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH} >/dev/null 2>&1 &
XVFB_PID=$!

# Start x11vnc for debugging (optional)
x11vnc -display :99 -forever -rfbauth /home/computeruse/.vnc/passwd -listen 0.0.0.0 -rfbport 5900 >/dev/null 2>&1 &
VNC_PID=$!

# Wait for X server
sleep 3

# Start XFCE
export DISPLAY=:99
startxfce4 >/dev/null 2>&1 &
XFCE_PID=$!

# Wait for desktop to initialize
sleep 5

# Start Firefox with remote debugging enabled
firefox-esr 
  --remote-debugging-port=9222 
  --new-instance 
  --width=${SCREEN_WIDTH} 
  --height=${SCREEN_HEIGHT} 
  about:blank >/dev/null 2>&1 &
BROWSER_PID=$!

echo "Container ready!"
echo "CDP endpoint: http://localhost:9222"
echo "VNC server: vnc://localhost:5900 (password: secret)"
echo "Display: :99 (${SCREEN_WIDTH}x${SCREEN_HEIGHT})"

# Cleanup function
cleanup() {
  echo "Shutting down..."
  kill $BROWSER_PID $XFCE_PID $VNC_PID $XVFB_PID 2>/dev/null
  exit 0
}

trap cleanup SIGTERM SIGINT

# Keep container running
wait