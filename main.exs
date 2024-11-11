# ping_pong.exs

defmodule PingPong do
  # Starts the ping-pong process with an initial counter
  def start(counter \\ 1) do
    IO.puts("Node #{Node.self()} started with counter: #{counter}")
    loop(counter)
  end

  defp loop(counter) do
    # Print the current state
    IO.puts("Node #{Node.self()} has counter: #{counter}")

    # Increment the counter and reset to 1 if it exceeds 11
    next_counter = if counter >= 11, do: 1, else: counter + 1

    # Get a list of all connected nodes, excluding the current node
    nodes = Node.list() |> Enum.reject(&(&1 == Node.self()))

    if nodes == [] do
      IO.puts("No other nodes to send to. Restarting...")
      :timer.sleep(1000)
      loop(next_counter)
    else
      # Choose a random node and send the next counter
      random_node = Enum.random(nodes)
      IO.puts("Node #{Node.self()} sending counter #{next_counter} to #{random_node}")

      # Spawn the next process on the chosen random node
      Node.spawn(random_node, PingPong, :start, [next_counter])

      # Halt this node's process as the counter is sent
      :timer.sleep(:infinity)
    end
  end
end

# Start the PingPong module
PingPong.start()
