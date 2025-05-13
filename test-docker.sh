#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing Docker Setup for User & Transaction Graph Environment ===${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker before running this script.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose before running this script.${NC}"
    exit 1
fi

# Build the containers
echo -e "${BLUE}Building containers...${NC}"
docker-compose build

# Start the containers
echo -e "${BLUE}Starting containers...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${BLUE}Waiting for services to be ready (this may take a minute)...${NC}"
sleep 10

# Test Neo4j
echo -e "${BLUE}Testing Neo4j connection...${NC}"
if docker-compose exec -T neo4j curl -s -o /dev/null -w "%{http_code}" http://localhost:7474 | grep -q "200"; then
    echo -e "${GREEN}Neo4j is running correctly.${NC}"
else
    echo -e "${RED}Neo4j is not responding correctly.${NC}"
    echo -e "${YELLOW}Checking Neo4j logs:${NC}"
    docker-compose logs neo4j
    exit 1
fi

# Test Backend API
echo -e "${BLUE}Testing Backend API...${NC}"
if docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200"; then
    echo -e "${GREEN}Backend API is running correctly.${NC}"
else
    echo -e "${RED}Backend API is not responding correctly.${NC}"
    echo -e "${YELLOW}Checking Backend logs:${NC}"
    docker-compose logs backend
    exit 1
fi

# Test Frontend
echo -e "${BLUE}Testing Frontend...${NC}"
if docker-compose exec -T frontend curl -s -o /dev/null -w "%{http_code}" http://localhost:5001 | grep -q "200"; then
    echo -e "${GREEN}Frontend is running correctly.${NC}"
else
    echo -e "${RED}Frontend is not responding correctly.${NC}"
    echo -e "${YELLOW}Checking Frontend logs:${NC}"
    docker-compose logs frontend
    exit 1
fi

# Test API endpoints
echo -e "${BLUE}Testing API endpoints...${NC}"

# Test graph data endpoint
echo -e "${BLUE}Testing graph data endpoint...${NC}"
if docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/graph-data | grep -q "200"; then
    echo -e "${GREEN}Graph data endpoint is working correctly.${NC}"
else
    echo -e "${RED}Graph data endpoint is not responding correctly.${NC}"
    exit 1
fi

# Test users endpoint
echo -e "${BLUE}Testing users endpoint...${NC}"
if docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/users | grep -q "200"; then
    echo -e "${GREEN}Users endpoint is working correctly.${NC}"
else
    echo -e "${RED}Users endpoint is not responding correctly.${NC}"
    exit 1
fi

# Test transactions endpoint
echo -e "${BLUE}Testing transactions endpoint...${NC}"
if docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/transactions | grep -q "200"; then
    echo -e "${GREEN}Transactions endpoint is working correctly.${NC}"
else
    echo -e "${RED}Transactions endpoint is not responding correctly.${NC}"
    exit 1
fi

# All tests passed
echo -e "\n${GREEN}=== All tests passed! ===${NC}"
echo -e "${GREEN}The Docker setup is working correctly.${NC}"
echo -e "\n${BLUE}You can access the application at:${NC}"
echo -e "  - Frontend: ${GREEN}http://localhost:5001${NC}"
echo -e "  - Backend API: ${GREEN}http://localhost:8000${NC}"
echo -e "  - Neo4j Browser: ${GREEN}http://localhost:7474${NC}"
echo -e "    (Neo4j credentials: neo4j/password)"

# Ask if the user wants to stop the containers
echo -e "\n${YELLOW}Do you want to stop the containers? (y/n)${NC}"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Stopping containers...${NC}"
    docker-compose down
    echo -e "${GREEN}Containers stopped.${NC}"
else
    echo -e "${BLUE}Containers are still running.${NC}"
    echo -e "${BLUE}You can stop them later with:${NC} docker-compose down"
fi
