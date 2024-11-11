defmodule PingPong do
  @moduledoc """
  A distributed Ping-Pong game where a number is passed between containers, incrementing each time.
  """

  @max_number 10
  @delay 1000  # 1-second delay

  def start(initial_number \\ 1) do
    # Only start the game from container 1
    if System.get_env("CONTAINER_NAME") == "elixir_container_1" do
      send_random(initial_number)
    else
      listen()
    end
  end

  defp listen do
    receive do
      {:ping, number} ->
        IO.puts("Container #{Node.self()} received number #{number}")
        Process.sleep(@delay)
        send_random(increment(number))
        listen()
    end
  end

  defp send_random(number) do
    # Get list of all nodes, excluding itself
    nodes = Node.list() |> Enum.reject(&(&1 == Node.self()))
    if nodes == [] do
      IO.puts("No other containers to send to.")
    else
      # Select a random node to send the message
      target_node = Enum.random(nodes)
      IO.puts("Container #{Node.self()} sending #{number} to #{target_node}")
      Node.spawn(target_node, __MODULE__, :listen, [])
      send {target_node, __MODULE__}, {:ping, number}
    end
  end

  defp increment(number) do
    if number >= @max_number, do: 1, else: number + 1
  end
end

# Start the PingPong module
PingPong.start()
