defmodule Utils do
  def common_prefix_length(a, b) do
    common_prefix_length(a, b, 0)
  end

  defp common_prefix_length(a, b, index) do
    if index == number_of_levels() || String.at(a, index) != String.at(b, index) do
      index
    else
      common_prefix_length(a, b, index + 1)
    end
  end

  def node_name(node_id) do
    :"#{node_id}"
  end

  def hash(node_id) do
    String.slice(:crypto.hash(:sha, "#{node_id}") |> Base.encode16(), 0..(number_of_levels() - 1))
  end

  def number_of_levels() do
    40
  end

  def nearest_neighbour(current_guid, filteredGuids) do
    current_guid_value = integer_value(current_guid)

    Enum.reduce(filteredGuids, nil, fn guid, minDiffGuid ->
      if minDiffGuid == nil do
        guid
      else
        if abs(current_guid_value - integer_value(guid)) >
             abs(current_guid_value - integer_value(minDiffGuid)) do
          minDiffGuid
        else
          guid
        end
      end
    end)
  end

  defp integer_value(guid) do
    String.to_integer(guid, 16)
  end
end
