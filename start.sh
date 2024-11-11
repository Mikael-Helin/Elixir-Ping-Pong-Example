#!/bin/sh

# Check for required environment variables
if [ -z "$NODE_NAME" ] || [ -z "$COOKIE" ]; then
  echo "NODE_NAME and COOKIE environment variables must be set"
  exit 1
fi

# Change to the directory where main.exs is located
cd /opt/app || exit

# Start the Elixir node with a short name
elixir --sname "$NODE_NAME" --cookie "$COOKIE" main.exs