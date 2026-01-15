#!/bin/bash

# CUA Challenge - Quick Start Script

echo "🚀 CUA Challenge - Starting Application"
echo "========================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a | grep -q cua-challenge; then
    echo "🧹 Cleaning up existing container..."
    docker stop cua-challenge 2>/dev/null
    docker rm cua-challenge 2>/dev/null
fi

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t cua-challenge . || {
    echo "❌ Failed to build Docker image"
    exit 1
}

# Run the container
echo "🏃 Starting container on port 8080..."
docker run -d -p 8080:80 --name cua-challenge cua-challenge || {
    echo "❌ Failed to start container"
    exit 1
}

# Wait a moment for the container to start
sleep 2

# Check if container is running
if docker ps | grep -q cua-challenge; then
    echo "✅ CUA Challenge is now running!"
    echo ""
    echo "🌐 Access the application at: http://localhost:8080"
    echo ""
    echo "📝 Useful commands:"
    echo "   Stop:    docker stop cua-challenge"
    echo "   Start:   docker start cua-challenge"
    echo "   Remove:  docker rm -f cua-challenge"
    echo "   Logs:    docker logs cua-challenge"
    echo ""
else
    echo "❌ Container failed to start. Check Docker logs:"
    echo "   docker logs cua-challenge"
    exit 1
fi
