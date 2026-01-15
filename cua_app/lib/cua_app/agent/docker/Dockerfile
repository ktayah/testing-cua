# Dockerfile for Anthropic Computer Use with Local Browser
# Based on OpenAI CUA sample but optimized for CDP access
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV SCREEN_WIDTH=1280
ENV SCREEN_HEIGHT=800
ENV SCREEN_DEPTH=24

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    xvfb \
    x11vnc \
    # Browser automation tools
    xdotool \
    wmctrl \
    # Utilities
    curl \
    wget \
    gnupg \
    unzip \
    imagemagick \
    x11-apps \
    sudo \
    software-properties-common \
    ca-certificates \
    openssl \
    locales \
    libstdc++6 \
    libncurses5 \
    file \
    # Remove screen lockers and power managers that might interfere
    && apt-get remove -y light-locker xfce4-screensaver xfce4-power-manager xfce4-session || true \
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

# Set x11vnc password for debugging (as root, then chown)
RUN mkdir -p /home/computeruse/.vnc \
    && x11vnc -storepasswd secret /home/computeruse/.vnc/passwd \
    && chown -R computeruse:computeruse /home/computeruse/.vnc

USER computeruse
WORKDIR /home/computeruse

# Copy startup script from host                                                                                                                                                                
COPY --chown=computeruse:computeruse ./start.sh /home/computeruse/start.sh                                                                                                                      
RUN chmod +x /home/computeruse/start.sh

# Expose ports
# 9222: Firefox DevTools Protocol
# 5900: VNC (for debugging/viewing)
EXPOSE 9222 5900

# Start services
CMD ["/home/computeruse/start.sh"]
