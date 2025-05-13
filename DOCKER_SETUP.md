# Docker Setup for User & Transaction Graph Environment

This document provides detailed instructions for setting up and running the User & Transaction Graph Environment using Docker.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

The easiest way to get started is to use the provided start script:

```bash
# Make the script executable (if not already)
chmod +x start.sh

# Run the script
./start.sh
```

This script will:
1. Build and start all containers
2. Wait for all services to be ready
3. Provide URLs to access the application

## Manual Setup

If you prefer to set up manually, follow these steps:

### 1. Build and Start the Containers

```bash
# For development (with local directory mounting)
docker-compose up -d

# For production (without local directory mounting)
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Access the Application

- **Frontend**: http://localhost:5001
- **Backend API**: http://localhost:8000
- **Neo4j Browser**: http://localhost:7474 (credentials: neo4j/password)

## Container Architecture

The Docker setup consists of three containers:

1. **Neo4j Database** (`graph-neo4j`)
   - Stores all graph data
   - Accessible at http://localhost:7474 (Browser) and bolt://localhost:7687 (Bolt protocol)
   - Uses persistent volumes for data and logs

2. **Backend API** (`graph-backend`)
   - Provides REST APIs for graph operations
   - Accessible at http://localhost:8000
   - Automatically initializes the database on startup (configurable)

3. **Frontend** (`graph-frontend`)
   - Provides the web interface for visualization
   - Accessible at http://localhost:5001
   - Communicates with the backend API

## Data Management

### Automatic Data Initialization

By default, the database is automatically initialized with test data on startup. You can control this behavior by setting the `AUTO_INIT_DB` environment variable in the docker-compose.yml file:

```yaml
backend:
  environment:
    - AUTO_INIT_DB=true  # Set to false to disable auto-initialization
```

### Generating Custom Test Data

You can generate custom test data using one of the following methods:

#### 1. Using the API Endpoint

```bash
# Generate data with default parameters
curl -X POST "http://localhost:8000/api/generate-data"

# Generate custom data
curl -X POST "http://localhost:8000/api/generate-data?num_users=20&num_companies=10&num_transactions=50"

# Generate data in the background
curl -X POST "http://localhost:8000/api/generate-data?run_in_background=true"
```

#### 2. Using the Script Inside the Container

```bash
# Generate data with default parameters
docker-compose exec backend /app/scripts/generate-data.sh

# Generate custom data
docker-compose exec backend /app/scripts/generate-data.sh --users=20 --companies=10 --transactions=50
```

#### 3. Initialize with Predefined Test Data

```bash
# Initialize with predefined test data
docker-compose exec backend /app/scripts/init-db.sh
```

## Exporting Data

You can export the graph data in various formats:

- **JSON**: http://localhost:8000/api/export/json
- **CSV**: http://localhost:8000/api/export/csv
- **Image**: Use the "Export as Image" button in the frontend

## Container Management

### Viewing Logs

```bash
# View logs from all containers
docker-compose logs -f

# View logs from a specific container
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f neo4j
```

### Stopping the Application

```bash
# Stop all containers
docker-compose down

# Stop all containers and remove volumes
docker-compose down -v
```

### Restarting the Application

```bash
# Restart all containers
docker-compose restart

# Restart a specific container
docker-compose restart backend
docker-compose restart frontend
docker-compose restart neo4j
```

## Troubleshooting

### Neo4j Connection Issues

If the backend cannot connect to Neo4j, check the following:

1. Make sure Neo4j is running:
   ```bash
   docker-compose ps
   ```

2. Check Neo4j logs:
   ```bash
   docker-compose logs neo4j
   ```

3. Verify the Neo4j connection parameters in the backend environment variables.

### Backend API Issues

If the frontend cannot connect to the backend API, check the following:

1. Make sure the backend is running:
   ```bash
   docker-compose ps
   ```

2. Check backend logs:
   ```bash
   docker-compose logs backend
   ```

3. Verify the backend connection parameters in the frontend environment variables.

## Production Deployment

For production deployment, use the production Docker Compose file:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

The production configuration:
- Does not mount local directories (all code is copied into the containers)
- Includes restart policies for containers
- Is optimized for stability and security

## Customization

### Changing Ports

If you need to change the default ports, modify the port mappings in the docker-compose.yml file:

```yaml
services:
  neo4j:
    ports:
      - "7474:7474"  # Change the first number to change the host port
      - "7687:7687"  # Change the first number to change the host port
  
  backend:
    ports:
      - "8000:8000"  # Change the first number to change the host port
  
  frontend:
    ports:
      - "5001:5001"  # Change the first number to change the host port
```

### Changing Neo4j Credentials

To change the Neo4j credentials, modify the environment variables in the docker-compose.yml file:

```yaml
services:
  neo4j:
    environment:
      - NEO4J_AUTH=neo4j/your_new_password
  
  backend:
    environment:
      - NEO4J_USER=neo4j
      - NEO4J_PASSWORD=your_new_password
```

## Security Considerations

For production deployments, consider the following security measures:

1. Change the default Neo4j password
2. Use a reverse proxy (like Nginx) with HTTPS
3. Implement proper authentication for the API
4. Restrict access to the Neo4j browser
5. Use Docker secrets for sensitive information
