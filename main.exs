defmodule PingPong do
  @moduledoc """
  A distributed Ping-Pong game where a number is passed between containers.
  """
  @max_number 10
  @delay 1000

  def start(initial_number \\ 1) do
    container_name = System.get_env("CONTAINER_NAME")
    IO.puts("Starting main.exs in container #{container_name}")
    IO.puts("Current Node: #{inspect(Node.self())}")
    IO.puts("Available nodes: #{inspect(Node.list())}")

    if container_name == "ping_pong_container_1" do
      IO.puts("Container #{container_name} is initiating the game with number #{initial_number}")
      do_send_random(initial_number)
    else
      IO.puts("Container #{container_name} is waiting to receive a number.")
      do_listen()
    end

    # Keep the process running
    :timer.sleep(:infinity)
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
      IO.puts("Container #{container_name} sending number #{number} to #{inspect(target_node)}")
      send({__MODULE__, target_node}, {:ping, number})
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
