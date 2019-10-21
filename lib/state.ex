defmodule ProjState do
  use GenServer

  @me __MODULE__

  ### Needed Methods

  def start_link(num_nodes, num_requests) do
    GenServer.start_link(@me, [num_nodes, num_requests], name: @me)
  end

  def init([num_nodes, num_requests]) do
    count = 0
    max = 0
    {:ok, {num_nodes, num_requests, count, max}}
  end

  ### Custom methods ###

  def is_completed() do
    GenServer.call(@me, {:is_completed})
  end

  def completed_requests() do
    GenServer.call(@me, {:completed_requests})
  end

  def max() do
    GenServer.call(@me, {:get_max})
  end

  def increase_count(number_of_hops) do
    GenServer.cast(@me, {:completed, number_of_hops})
  end

  ### Callbacks ###

  def handle_call({:is_completed}, _from, {num_nodes, num_requests, count, max}) do
    is_completed = num_requests * num_nodes == count
    {:reply, is_completed, {num_nodes, num_requests, count, max}}
  end

  def handle_call({:completed_requests}, _from, {num_nodes, num_requests, count, max}) do
    {:reply, count, {num_nodes, num_requests, count, max}}
  end

  def handle_call({:get_max}, _from, {num_nodes, num_requests, count, max}) do
    {:reply, max, {num_nodes, num_requests, count, max}}
  end

  def handle_cast({:completed, number_of_hops}, {num_nodes, num_requests, count, max}) do
    max =
      if max < number_of_hops do
        number_of_hops
      else
        max
      end

    {:noreply, {num_nodes, num_requests, count + 1, max}}
  end
end
