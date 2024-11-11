defmodule PingPong do
  @moduledoc """
  A distributed Ping-Pong game where a number is passed between containers.
  """
  @max_number 10
  @delay 1000
  @total_nodes 3  # Adjust this number based on the total number of nodes

  def start(initial_number \\ 1) do
    container_name = System.get_env("CONTAINER_NAME")
    IO.puts("Starting main.exs in container #{container_name}")
    IO.puts("Current Node: #{inspect(Node.self())}")

    # Register the process once
    Process.register(self(), :ping_pong_process)
    IO.puts("Process registered as :ping_pong_process")

    # Connect to other nodes
    connect_to_other_nodes()
    # Wait for connections to establish
    Process.sleep(2000)

    IO.puts("Available nodes: #{inspect(Node.list())}")

    if container_name == "ping_pong_container_1" do
      IO.puts("Container #{container_name} is initiating the game with number #{initial_number}")
      do_send_random(initial_number)
    else
      IO.puts("Container #{container_name} is waiting to receive a number.")
    end

    # Start listening
    do_listen()
  end

  defp connect_to_other_nodes do
    for i <- 1..@total_nodes do
      node_name = :"node_#{i}@ping_pong"
      unless node_name == Node.self() do
        IO.puts("Attempting to connect to #{inspect(node_name)}")
        Node.connect(node_name)
      end
    end
  end

  def do_send_random(number) do
    nodes = Node.list()
    container_name = System.get_env("CONTAINER_NAME")

    if nodes == [] do
      IO.puts("No other nodes available to send number #{number} from #{container_name}.")
      # Wait and retry
      Process.sleep(2000)
      do_send_random(number)
    else
      target_node = Enum.random(nodes)
      IO.puts("Container #{container_name} sending number #{number} to :ping_pong_process@#{inspect(target_node)}")
      send({:ping_pong_process, target_node}, {:ping, number})
    end
  end

  def do_listen do
    IO.puts("Listening for messages...")
    receive do
      {:ping, number} ->
        container_name = System.get_env("CONTAINER_NAME")
        IO.puts("Container #{container_name} received number #{number}")
        Process.sleep(@delay)
        do_send_random(increment(number))
        do_listen()
      after
        5000 ->
          IO.puts("No messages received in the last 5 seconds.")
          do_listen()
    end
  end

  defp increment(number) do
    if number >= @max_number, do: 1, else: number + 1
  end
end

# Start the PingPong module
PingPong.start()
