defmodule ProjApplication do
  use Application

  ### We will insert 10 % nodes dynamically
  @dynamic_insertion_percentage 10

  ### Every @log_interval milliseconds we check how many requests have been initialized
  @log_interval 5_000

  ### While waiting everything to finish, we sleep for @sleep_time milliseconds to check if application completed
  @sleep_time 100

  def start(_type, _args) do
    [num_nodes, num_requests] = Enum.map(System.argv(), fn x -> String.to_integer(x) end)

    if num_nodes <= 1 do
      IO.puts("Number of nodes should be greater than 1")
    else
      init_num_nodes = num_nodes - round(num_nodes * @dynamic_insertion_percentage / 100)

      guid_to_node_id =
        Enum.into(
          Enum.map(1..init_num_nodes, fn node_id -> {Utils.hash(node_id), node_id} end),
          %{}
        )

      IO.puts("Initialize DHT")
      dht_per_node = DhtSupervisor.init_dht(Map.keys(guid_to_node_id))

      ## Start Supervisor
      ProjSupervisor.start_link()

      ## Initialize State
      ProjSupervisor.start_state(num_nodes, num_requests)

      ## Initialize workers
      initialize_workers(init_num_nodes, num_requests, guid_to_node_id, dht_per_node)

      IO.puts "Insert nodes dynamically"
      # Insert node dynamically
      _guid_to_node_id =
        if init_num_nodes != num_nodes do
          Enum.reduce((init_num_nodes + 1)..num_nodes, guid_to_node_id, fn node_id, g_to_n_id ->
            add_new_node(node_id, num_requests, g_to_n_id)
          end)
        end

      IO.puts("Start Requests")
      ## Start Requests
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

  defp add_new_node(node_id, num_requests, guid_to_node_id) do
    new_node_guid = Utils.hash(node_id)
    guid_to_node_id = Map.put(guid_to_node_id, new_node_guid, node_id)
    all_guids = Map.keys(guid_to_node_id)

    dht = DhtWorker.dht_for_guid(all_guids, new_node_guid)

    ProjSupervisor.start_worker(
      node_id,
      new_node_guid,
      dht,
      num_requests,
      guid_to_node_id
    )

    notify_neighbours(node_id, new_node_guid, dht, guid_to_node_id)
    guid_to_node_id
  end

  defp notify_neighbours(current_node_id, current_guid, dht, guid_to_node_id) do
    Enum.each(dht, fn {level, hex_map} ->
      Enum.each(hex_map, fn {_hex, node_guid} ->
        GenServer.cast(
          Utils.node_name(Map.get(guid_to_node_id, node_guid)),
          {:update_dht_for_new_node, current_node_id, current_guid, level}
        )
      end)
    end)
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
          # IO.puts("Completed request count #{ProjState.completed_requests()}")
          current_time
        else
          last_checked
        end

      lets_wait(last_checked)
    end
  end
end
