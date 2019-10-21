defmodule ProjSupervisor do
  use DynamicSupervisor
  @me __MODULE__

  def start_link() do
    DynamicSupervisor.start_link(@me, :ok, name: @me)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_state(num_nodes, num_requests) do
    spec = %{id: ProjState, start: {ProjState, :start_link, [num_nodes, num_requests]}}
    DynamicSupervisor.start_child(@me, spec)
  end

  def start_worker(node_id, guid, dht, num_requests, guid_to_node_id) do
    spec = %{
      id: ProjWorker,
      start: {ProjWorker, :start_link, [node_id, guid, dht, num_requests, guid_to_node_id]}
    }

    DynamicSupervisor.start_child(@me, spec)
  end
end
