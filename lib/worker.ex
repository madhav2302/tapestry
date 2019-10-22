defmodule ProjWorker do
  use GenServer

  ### 1 sec
  @interval 1_000

  def start_link(node_id, guid, dht, num_requests, guid_to_node_id) do
    GenServer.start_link(__MODULE__, [node_id, guid, dht, num_requests, guid_to_node_id],
      name: node_name(node_id)
    )
  end

  def init([node_id, guid, dht, num_requests, guid_to_node_id]) do
    request_count = 0
    {:ok, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def handle_cast(
        {:search_node, search_by, search_guid, hop},
        {node_id, guid, dht, num_requests, guid_to_node_id, request_count}
      ) do
    common_prefix_length = common_prefix_length(guid, search_guid, 0)

    if common_prefix_length != 40 do
      {next_guid, _backpointer} =
        Map.get(
          Map.get(dht, common_prefix_length),
          String.slice(search_guid, 0..common_prefix_length)
        )

      GenServer.cast(
        node_name(Map.get(guid_to_node_id, next_guid)),
        {:search_node, search_by, search_guid, hop + 1}
      )
    else
      ProjState.increase_count(hop)
      # IO.puts("Found #{search_guid} on #{hop} which is searched by #{search_by}")
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
        GenServer.cast(node_name(node_id), {:search_node, guid, search_guid, 0})
        Process.send_after(self(), {:start_search}, @interval)
        request_count + 1
      end

    {:noreply, {node_id, guid, dht, num_requests, guid_to_node_id, request_count}}
  end

  def node_name(node_id) do
    :"#{node_id}"
  end

  defp common_prefix_length(self_guid, search_guid, index) do
    if index == 40 || String.at(self_guid, index) != String.at(search_guid, index) do
      index
    else
      common_prefix_length(self_guid, search_guid, index + 1)
    end
  end
end
