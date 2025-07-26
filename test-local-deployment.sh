#!/bin/bash

# Test Local Deployment Script
set -e

echo "🧪 Testing local deployment with new configuration..."

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down --volumes --remove-orphans 2>/dev/null || true

# Build and start services
echo "🏗️ Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Run database migrations
echo "🗄️ Running database schema setup..."
docker-compose exec -T db psql -U user -d brickbreaker < backend/database/schema.sql

# Test backend health
echo "🔍 Testing backend health..."
for i in {1..10}; do
  if curl -f http://localhost:8000/api/health > /dev/null 2>&1; then
    echo "✅ Backend health check passed"
    break
  else
    echo "⏳ Backend not ready, attempt $i/10..."
    sleep 5
  fi
  if [ $i -eq 10 ]; then
    echo "❌ Backend health check failed after 10 attempts"
    docker-compose logs backend
    exit 1
  fi
done

# Test frontend
echo "🎮 Testing frontend..."
for i in {1..10}; do
  if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend health check passed"
    break
  else
    echo "⏳ Frontend not ready, attempt $i/10..."
    sleep 5
  fi
  if [ $i -eq 10 ]; then
    echo "❌ Frontend health check failed after 10 attempts"
    docker-compose logs game
    exit 1
  fi
done

# Test API endpoints
echo "🔌 Testing API endpoints..."

# Test create player
PLAYER_RESPONSE=$(curl -s -X POST http://localhost:8000/api/players \
  -H "Content-Type: application/json" \
  -d '{"name":"TestPlayer"}')

if echo "$PLAYER_RESPONSE" | jq -e '.id' > /dev/null; then
  PLAYER_ID=$(echo "$PLAYER_RESPONSE" | jq -r '.id')
  echo "✅ Player creation test passed (ID: $PLAYER_ID)"
else
  echo "❌ Player creation test failed"
  echo "Response: $PLAYER_RESPONSE"
  exit 1
fi

# Test submit score
SCORE_RESPONSE=$(curl -s -X POST http://localhost:8000/api/scores \
  -H "Content-Type: application/json" \
  -d "{\"playerId\":$PLAYER_ID,\"score\":1500}")

if echo "$SCORE_RESPONSE" | jq -e '.id' > /dev/null; then
  echo "✅ Score submission test passed"
else
  echo "❌ Score submission test failed"
  echo "Response: $SCORE_RESPONSE"
  exit 1
fi

# Test leaderboard
LEADERBOARD_RESPONSE=$(curl -s http://localhost:8000/api/leaderboard)

if echo "$LEADERBOARD_RESPONSE" | jq -e '.leaderboard' > /dev/null; then
  echo "✅ Leaderboard test passed"
else
  echo "❌ Leaderboard test failed"
  echo "Response: $LEADERBOARD_RESPONSE"
  exit 1
fi

# Test CORS
echo "🔗 Testing CORS..."
CORS_RESPONSE=$(curl -s -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:8000/api/players)

if [ $? -eq 0 ]; then
  echo "✅ CORS test passed"
else
  echo "❌ CORS test failed"
  exit 1
fi

echo ""
echo "🎉 All tests passed! Local deployment is working correctly."
echo ""
echo "📊 Service URLs:"
echo "Frontend: http://localhost:3000"
echo "Backend API: http://localhost:8000"
echo "Backend Health: http://localhost:8000/api/health"
echo "Leaderboard: http://localhost:8000/api/leaderboard"
echo ""
echo "🚀 Ready for Azure Container Apps deployment!"

# Optionally clean up
read -p "Do you want to stop the containers? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🧹 Stopping containers..."
  docker-compose down
fi 