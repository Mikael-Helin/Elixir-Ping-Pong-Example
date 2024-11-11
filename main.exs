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

    # Check if this container is the initiator and start the game
    if container_name == "ping_pong_1_1" do
      IO.puts("Container #{container_name} is initiating the game with number #{initial_number}")
      do_send_random(initial_number)
    else
      IO.puts("Container #{container_name} is waiting to receive a number.")
    end

    # Start listening for incoming messages
    do_listen()
  end

  defp connect_to_other_nodes do
    total_pods = System.get_env("NUM_PODS") |> String.to_integer()
    containers_per_pod = System.get_env("NUM_CONTAINERS") |> String.to_integer()

    Process.sleep(2000)  # Delay to allow nodes to initialize

    # Dynamically generate node names
    nodes = for pod_num <- 1..total_pods, container_num <- 1..containers_per_pod do
      :"ping_pong_#{pod_num}_#{container_num}@ping_pong_#{pod_num}"
    end


    for node <- nodes do
      unless node == Node.self() do
        IO.puts("Attempting to connect to #{inspect(node)}")
        Node.connect(node)
        case Node.ping(node) do
          :pong -> IO.puts("Successfully connected to #{inspect(node)}")
          :pang -> IO.puts("Failed to connect to #{inspect(node)}")
        end
      end
    end
  end

  def do_send_random(number) do
    nodes = Node.list()
    container_name = System.get_env("CONTAINER_NAME")

    if nodes == [] do
      IO.puts("No other nodes available to send number #{number} from #{container_name}. Retrying in 5 seconds.")
      Process.sleep(5000)
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
