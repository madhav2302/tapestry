defmodule DhtWorker do
  use GenServer

  @log_interval 1_000

  def start_link(all_guids, guids_to_process) do
    GenServer.start_link(__MODULE__, [all_guids, guids_to_process])
  end

  def init([all_guids, guids_to_process]) do
    result = %{}
    processed = false
    {:ok, {all_guids, guids_to_process, result, processed}}
  end

  def handle_call({:is_completed}, _from, {all_guids, guids_to_process, result, processed}) do
    {:reply, processed, {all_guids, guids_to_process, result, processed}}
  end

  def handle_call({:get_result}, _from, {all_guids, guids_to_process, result, processed}) do
    {:reply, result, {all_guids, guids_to_process, result, processed}}
  end

  def handle_cast(
        {:start_work},
        {all_guids, guids_to_process, _result, _processed}
      ) do
    last_checked = 0
    index = 0

    dht_per_node = iterate_over_guids(all_guids, guids_to_process, index, %{}, last_checked)

    processed = true
    {:noreply, {all_guids, guids_to_process, dht_per_node, processed}}
  end

  defp iterate_over_guids(
         all_guids,
         guids_to_process,
         index,
         result,
         last_checked
       ) do
    if index == guids_to_process |> length() do
      result
    else
      # Change this
      current_guid = Enum.at(guids_to_process, index)

      current_result = iterate_over_levels(all_guids, 0, current_guid, %{})

      result = Map.put(result, current_guid, current_result)

      current_time = System.system_time(:millisecond)

      # IO.puts "Current Time : #{current_time}, last_checked : #{last_checked}"
      last_checked =
        if current_time - last_checked > @log_interval do
          # IO.puts("Completed dht till #{index}")
          current_time
        else
          last_checked
        end

      iterate_over_guids(all_guids, guids_to_process, index + 1, result, last_checked)
    end
  end

  def dht_for_guid(all_guids, guid) do
    iterate_over_levels(all_guids, 0, guid, %{})
  end

  defp iterate_over_levels(guids, index, current_guid, result) do
    if index == Utils.number_of_levels() do
      result
    else
      current = String.slice(current_guid, 0..index)

      prefix =
        if index == 0 do
          ""
        else
          String.slice(current_guid, 0..(index - 1))
        end

      current_result =
        iterate_over_hex(
          guids,
          current_guid,
          0,
          current,
          prefix,
          %{}
        )

      result = Map.put(result, index, current_result)

      iterate_over_levels(
        guids,
        index + 1,
        current_guid,
        result
      )
    end
  end

  defp iterate_over_hex(
         guids,
         current_guid,
         index,
         current,
         prefix,
         result
       ) do
    if index == 16 do
      result
    else
      newPrefix = "#{prefix}#{Integer.to_string(index, 16)}"

      filteredGuids = Enum.filter(guids, fn guid -> String.starts_with?(guid, newPrefix) end)

      result =
        if filteredGuids |> length() != 0 && "#{current}" != "#{newPrefix}" do
          Map.put(
            result,
            Integer.to_string(index, 16),
            Utils.nearest_neighbour(current_guid, filteredGuids)
          )
        else
          result
        end

      iterate_over_hex(
        guids,
        current_guid,
        index + 1,
        current,
        prefix,
        result
      )
    end
  end
end
