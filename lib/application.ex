defmodule ProjApplication do
  use Application

  @log_interval 5_000
  @sleep_time 10

  def start(_type, _args) do
    [num_nodes, num_requests] = Enum.map(System.argv(), fn x -> String.to_integer(x) end)

    if num_nodes <= 1 do
      IO.puts("Number of nodes should be greater than 1")
    else
      guid_to_node_id =
        Enum.into(Enum.map(1..num_nodes, fn node_id -> {Utils.hash(node_id), node_id} end), %{})

      IO.puts("Initialize DHT")
      dht_per_node = DhtSupervisor.init_dht(Map.keys(guid_to_node_id))

      # Start Supervisor
      ProjSupervisor.start_link()

      ## Initialize State
      ProjSupervisor.start_state(num_nodes, num_requests)

      ## Initialize workers
      initialize_workers(num_nodes, num_requests, guid_to_node_id, dht_per_node)

      IO.puts("Started Searching")

      ## Initialize searching
      Enum.each(1..num_nodes, fn node_id ->
        GenServer.cast(Utils.node_name(node_id), {:start_work})
      end)

      ## Wait for everyone to complete
      lets_wait(0)

      ## Print max number of hops
      IO.puts("Max number of hops taken are #{ProjState.max()}")
    end

    {:ok, self()}
  end

  defp initialize_workers(num_nodes, num_requests, guid_to_node_id, dht_per_node) do
    node_id_to_guid = Enum.into(Enum.map(guid_to_node_id, fn {k, v} -> {v, k} end), %{})

    Enum.each(1..num_nodes, fn node_id ->
      guid = Map.get(node_id_to_guid, node_id)

      ProjSupervisor.start_worker(
        node_id,
        guid,
        Map.get(dht_per_node, guid),
        num_requests,
        guid_to_node_id
      )
    end)
  end

  defp lets_wait(last_checked) do
    if ProjState.is_completed() do
      nil
    else
      :timer.sleep(@sleep_time)
      current_time = System.system_time(:millisecond)

      last_checked =
        if current_time - last_checked > @log_interval do
          IO.puts("Completed request count #{ProjState.completed_requests()}")
          current_time
        else
          last_checked
        end

      lets_wait(last_checked)
    end
  end
end
