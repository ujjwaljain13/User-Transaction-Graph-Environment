#!/bin/bash

# Install Flask if not already installed
pip install flask

# Run the Flask server
cd frontend
python server.py

echo "Frontend server is running at http://localhost:5001"
