#!/bin/bash

# Production deployment script for Transaction Management API
# This script is called by the webhook receiver

set -e  # Exit on any error

echo "Starting deployment..."
echo "======================="

# Configuration with environment variable defaults
DOCKER_IMAGE=${DOCKER_IMAGE:-"ghcr.io/sahilbharodiya/transaction-management-api:latest"}
CONTAINER_NAME=${CONTAINER_NAME:-"transaction-api"}
HOST_PORT=${HOST_PORT:-"8000"}
CONTAINER_PORT=${CONTAINER_PORT:-"8000"}
DATA_DIR=${DATA_DIR:-"$(pwd)/data"}
COMMIT_SHA=${COMMIT_SHA:-"unknown"}

echo "Deployment Configuration:"
echo "- Docker Image: $DOCKER_IMAGE"
echo "- Container Name: $CONTAINER_NAME"
echo "- Port Mapping: $HOST_PORT:$CONTAINER_PORT"
echo "- Data Directory: $DATA_DIR"
echo "- Commit SHA: $COMMIT_SHA"
echo ""

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Pull the latest image
echo "Pulling Docker image..."
if ! docker pull "$DOCKER_IMAGE"; then
    echo "❌ Failed to pull Docker image: $DOCKER_IMAGE"
    exit 1
fi

# Stop and remove existing container
echo "Stopping existing container..."
if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
    docker stop "$CONTAINER_NAME"
    echo "   Stopped container: $CONTAINER_NAME"
else
    echo "   No running container found"
fi

if docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q .; then
    docker rm "$CONTAINER_NAME"
    echo "   Removed container: $CONTAINER_NAME"
fi

# Start new container
echo "Starting new container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$HOST_PORT:$CONTAINER_PORT" \
    -v "$DATA_DIR:/app/data" \
    -e FLASK_ENV=production \
    -e COMMIT_SHA="$COMMIT_SHA" \
    "$DOCKER_IMAGE"

if [ $? -eq 0 ]; then
    echo "✅ Container started successfully"
else
    echo "❌ Failed to start container"
    exit 1
fi

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 10

# Health check
echo "Performing health check..."
for i in {1..5}; do
    if curl -f -s "http://localhost:$HOST_PORT/health" > /dev/null; then
        echo "✅ Health check passed (attempt $i)"
        break
    else
        echo "⏳ Health check failed, retrying... (attempt $i/5)"
        if [ $i -eq 5 ]; then
            echo "❌ Health check failed after 5 attempts"
            echo "Container logs:"
            docker logs "$CONTAINER_NAME" --tail 20
            exit 1
        fi
        sleep 10
    fi
done

# Show container status
echo ""
echo "Deployment Summary:"
echo "=================="
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 Deployment completed successfully!"
echo "API is running at: http://localhost:$HOST_PORT"
echo "Health check: http://localhost:$HOST_PORT/health"
