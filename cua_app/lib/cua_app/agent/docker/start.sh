#!/bin/bash
set -e

# Start Xvfb
Xvfb :99 -screen 0 ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH} >/dev/null 2>&1 &
XVFB_PID=$!

# Start x11vnc for debugging
x11vnc -display :99 -forever -rfbauth /home/computeruse/.vncpass -listen 0.0.0.0 -rfbport 5900 >/dev/null 2>&1 &
VNC_PID=$!

# Wait for X server
sleep 2

# Start XFCE
export DISPLAY=:99
startxfce4 >/dev/null 2>&1 &
XFCE_PID=$!

# Wait for desktop to initialize
sleep 3

# Create Firefox profile with preferences to disable problematic features
PROFILE_DIR="/home/computeruse/.mozilla/firefox-esr/cua.default-esr"
mkdir -p "$PROFILE_DIR"

# Create user.js with preferences to disable backups, telemetry, and other problematic features
cat > "$PROFILE_DIR/user.js" <<'EOF'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.backups.enabled", false);
user_pref("browser.backups.scheduled.enabled", false);
user_pref("security.sandbox.content.level", 0);
user_pref("security.sandbox.gpu.level", 0);
user_pref("security.sandbox.rdd.level", 0);
EOF

# Create profiles.ini if it doesn't exist
if [ ! -f "/home/computeruse/.mozilla/firefox-esr/profiles.ini" ]; then
  cat > "/home/computeruse/.mozilla/firefox-esr/profiles.ini" <<EOF
[Profile0]
Name=default
IsRelative=1
Path=cua.default-esr
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF
fi

# Start Firefox with remote debugging enabled
firefox-esr \
  -profile "$PROFILE_DIR" \
  --remote-debugging-port=9222 \
  --new-instance \
  --width=${SCREEN_WIDTH} \
  --height=${SCREEN_HEIGHT} \
  about:blank >/dev/null 2>&1 &
BROWSER_PID=$!

echo "Container ready!"
echo "CDP endpoint: http://localhost:9222"
echo "VNC server: vnc://localhost:5900 (password: secret)"
echo "Display: :99 (${SCREEN_WIDTH}x${SCREEN_HEIGHT})"

# Cleanup function
cleanup() {
  echo "Shutting down..."
  kill $BROWSER_PID $XFCE_PID $VNC_PID $XVFB_PID 2>/dev/null || true
  exit 0
}

trap cleanup SIGTERM SIGINT

# Keep container running
wait