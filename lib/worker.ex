defmodule ProjWorker do
  use GenServer

  ### 1 sec
  @interval 1_000

  def start_link(node_id, guid, dht, num_requests, guid_to_node_id) do
    GenServer.start_link(__MODULE__, [node_id, guid, dht, num_requests, guid_to_node_id],
      name: Utils.node_name(node_id)
    )
  end

  def init([node_id, guid, dht, num_requests, guid_to_node_id]) do
    request_count = 0
    {:ok, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def handle_cast(
        {:update_dht_for_new_node, new_node_id, new_node_guid, level},
        {node_id, guid, dht, num_requests, guid_to_node_id, request_count}
      ) do
    guid_to_node_id = Map.put(guid_to_node_id, new_node_guid, new_node_id)

    levelMap = Map.get(dht, level)
    hex = String.at(new_node_guid, level)

    levelMap =
      if Map.has_key?(levelMap, hex) do
        node_at_hex = Map.get(levelMap, hex)
        Map.put(levelMap, hex, Utils.nearest_neighbour(guid, [node_at_hex, new_node_guid]))
      else
        Map.put(levelMap, hex, new_node_guid)
      end

    dht = Map.put(dht, level, levelMap)
    {:noreply, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def handle_cast(
        {:search_node, search_by, search_guid, hop},
        {node_id, guid, dht, num_requests, guid_to_node_id, request_count}
      ) do
    common_prefix_length = Utils.common_prefix_length(guid, search_guid)

    if common_prefix_length != 40 do
      {next_guid, increase_count} =
        nearest_neighbour(
          Map.get(dht, common_prefix_length),
          String.at(search_guid, common_prefix_length)
        )

      if increase_count do
        ProjState.increase_count(search_by, hop)
      else
        GenServer.cast(
          Utils.node_name(Map.get(guid_to_node_id, next_guid)),
          {:search_node, search_by, search_guid, hop + 1}
        )
      end
    else
      ProjState.increase_count(search_by, hop)
    end

    {:noreply, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def handle_cast(
        {:start_work},
        {node_id, guid, dht, num_requests, guid_to_node_id, request_count}
      ) do
    send(self(), {:start_search})
    {:noreply, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def handle_info(
        {:start_search},
        {node_id, guid, dht, num_requests, guid_to_node_id, request_count}
      ) do
    request_count =
      if request_count == num_requests do
        request_count
      else
        search_guid = Enum.random(Map.keys(guid_to_node_id) -- [guid])
        GenServer.cast(Utils.node_name(node_id), {:search_node, guid, search_guid, 0})
        Process.send_after(self(), {:start_search}, @interval)
        request_count + 1
      end

    {:noreply, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  defp nearest_neighbour(level_map, hex) do
    if map_size(level_map) == 0 do
      {nil, true}
    else
      next_guid = Map.get(level_map, hex)

      if is_nil(next_guid) do
        {next_guid, __} =
          nearest_neighbour(
            level_map,
            Integer.to_string(rem(String.to_integer(hex, 16) + 1, 16), 16)
          )
        {next_guid, false}
      else
        {next_guid, false}
      end
    end
  end
end
