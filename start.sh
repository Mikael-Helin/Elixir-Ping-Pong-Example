#!/bin/sh

# Check for required environment variables
if [ -z "$NODE_NAME" ] || [ -z "$COOKIE" ]; then
  echo "NODE_NAME and COOKIE environment variables must be set"
  exit 1
fi

# Start the Elixir node
elixir --name "$NODE_NAME" --cookie "$COOKIE" main.exs