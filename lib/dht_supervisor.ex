defmodule DhtSupervisor do
  use DynamicSupervisor
  @me __MODULE__

  def start_link() do
    DynamicSupervisor.start_link(@me, :ok, name: @me)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_worker(all_guids, guids_to_process) do
    spec = %{
      id: DhtWorker,
      start: {DhtWorker, :start_link, [all_guids, guids_to_process]}
    }

    DynamicSupervisor.start_child(@me, spec)
  end

  ### Structure of dht_per_node : guid -> levels -> {level_value_for_each_hex_value, backpointer}
  def init_dht(guids) do
    DhtSupervisor.start_link()
    chunk_size = 100

    pids =
      Enum.map(Enum.chunk_every(guids, chunk_size), fn guids_to_process ->
        {__, pid} = DhtSupervisor.start_worker(guids, guids_to_process)
        pid
      end)

    Enum.each(pids, fn pid -> GenServer.cast(pid, {:start_work}) end)

    get_result(pids, %{})
  end

  defp get_result(pids, result) do
    if pids |> length() == 0 do
      result
    else
      pid = Enum.at(pids, 0)

      if GenServer.call(pid, {:is_completed}, :infinity) do
        dht_for_pid = GenServer.call(pid, {:get_result})
        get_result(Enum.slice(pids, 1..(pids |> length())), Map.merge(dht_for_pid, result))
      else
        get_result(pids, result)
      end
    end
  end
end
