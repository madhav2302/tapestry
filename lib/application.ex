defmodule ProjApplication do
  use Application

  @log_interval 1_000
  @sleep_time 10
  @number_of_levels 40

  def start(_type, _args) do
    [num_nodes, num_requests] = Enum.map(System.argv(), fn x -> String.to_integer(x) end)

    if num_nodes <= 1 do
      IO.puts("Number of nodes should be greater than 1")
    else
      # Start Supervisor
      ProjSupervisor.start_link()

      guid_to_node_id =
        Enum.into(Enum.map(1..num_nodes, fn node_id -> {hash(node_id), node_id} end), %{})

      node_id_to_guid = Enum.into(Enum.map(guid_to_node_id, fn {k, v} -> {v, k} end), %{})

      IO.puts("Initialize DHT")

      ### Structure of dht_per_node : guid -> levels -> {level_value_for_each_hex_value, backpointer}
      {dht_per_node, _filtered_guids_cache} =
        iterate_over_guids(Map.values(node_id_to_guid), 0, %{}, %{})

      ## Initialize State
      ProjSupervisor.start_state(num_nodes, num_requests)

      ## Initialize workers
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

      IO.puts("Started Searching")

      ## Initialize searching
      Enum.each(1..num_nodes, fn node_id ->
        GenServer.cast(ProjWorker.node_name(node_id), {:start_work})
      end)

      ## Wait for everyone to complete
      lets_wait(0)

      ## Print max number of hops
      IO.puts("Max number of hops taken are #{ProjState.max()}")
    end

    {:ok, self()}
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

  defp iterate_over_guids(guids, index, result, filtered_guids_cache) do
    if index == guids |> length() do
      {result, filtered_guids_cache}
    else
      current_guid = Enum.at(guids, index)

      {current_result, filtered_guids_cache} =
        iterate_over_levels(guids, 0, current_guid, %{}, filtered_guids_cache)

      result = Map.put(result, current_guid, current_result)

      iterate_over_guids(guids, index + 1, result, filtered_guids_cache)
    end
  end

  defp iterate_over_levels(guids, index, current_guid, result, filtered_guids_cache) do
    if index == @number_of_levels do
      {result, filtered_guids_cache}
    else
      current = String.slice(current_guid, 0..index)

      prefix =
        if index == 0 do
          ""
        else
          String.slice(current_guid, 0..(index - 1))
        end

      {current_result, filtered_guids_cache} =
        iterate_over_hex(
          guids,
          current_guid,
          0,
          current,
          prefix,
          %{},
          filtered_guids_cache
        )

      result = Map.put(result, index, current_result)

      iterate_over_levels(
        guids,
        index + 1,
        current_guid,
        result,
        filtered_guids_cache
      )
    end
  end

  defp iterate_over_hex(
         guids,
         current_guid,
         index,
         current,
         prefix,
         result,
         filtered_guids_cache
       ) do
    if index == 16 do
      {result, filtered_guids_cache}
    else
      newPrefix = "#{prefix}#{Integer.to_string(index, 16)}"

      {filteredGuids, filtered_guids_cache} =
        if Map.has_key?(filtered_guids_cache, newPrefix) do
          {Map.get(filtered_guids_cache, newPrefix), filtered_guids_cache}
        else
          iFilteredGuids = Enum.filter(guids, fn guid -> String.starts_with?(guid, newPrefix) end)
          {iFilteredGuids, Map.put(filtered_guids_cache, newPrefix, iFilteredGuids)}
        end

      result =
        if filteredGuids |> length() != 0 && "#{current}" != "#{newPrefix}" do
          ## TODO  : Choose nearest neighbour
          Map.put(result, newPrefix, {Enum.random(filteredGuids), current_guid})
        else
          result
        end

      iterate_over_hex(
        guids,
        current_guid,
        index + 1,
        current,
        prefix,
        result,
        filtered_guids_cache
      )
    end
  end

  defp hash(node_id) do
    String.slice(:crypto.hash(:sha, "#{node_id}") |> Base.encode16(), 0..(@number_of_levels - 1))
  end
end
