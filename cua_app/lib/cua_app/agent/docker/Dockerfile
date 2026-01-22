# Dockerfile for Anthropic Computer Use with Local Browser
# Based on OpenAI CUA sample but optimized for CDP access
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV SCREEN_WIDTH=1280
ENV SCREEN_HEIGHT=800
ENV SCREEN_DEPTH=24
# Disable Firefox sandboxing in containerENV MOZ_DISABLE_CONTENT_SANDBOX=1
ENV MOZ_DISABLE_GMP_SANDBOX=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    xvfb \
    xdotool \
    imagemagick \
    x11-apps \
    sudo \
    software-properties-common \
    && apt-get remove -y light-locker xfce4-screensaver xfce4-power-manager || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Firefox ESR from Mozilla PPA
RUN add-apt-repository ppa:mozillateam/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox-esr \
    && update-alternatives --set x-www-browser /usr/bin/firefox-esr \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -ms /bin/bash computeruse \
    && echo "computeruse ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER computeruse
WORKDIR /home/computeruse

# Set x11vnc password
RUN x11vnc -storepasswd secret /home/computeruse/.vncpass

# Pre-create Firefox profile directories to avoid runtime errors
RUN mkdir -p /home/computeruse/.mozilla/firefox-esr \
    && mkdir -p /home/computeruse/.cache/mozilla/firefox

# Copy startup script from host
COPY --chown=computeruse:computeruse ./start.sh /home/computeruse/start.sh
RUN chmod +x /home/computeruse/start.sh

# Expose ports
# 9222: Firefox DevTools Protocol
# 5900: VNC (for debugging/viewing)
EXPOSE 9222 5900

# Start services
CMD ["/home/computeruse/start.sh"]
