defmodule AbsintheRemote.Result do
  @moduledoc """
  A result handler that keeps atom keys.

  From the `absinthe_phoenix` project @ https://github.com/absinthe-graphql/absinthe_phoenix/blob/5f9e9e2b953bb15a1bb89bbe4810959bdeb12367/lib/absinthe/phoenix/controller/result.ex
  """

  # Produces data fit for external encoding from annotated value tree

  require Logger

  alias Absinthe.{Blueprint, Phase, Type}
  use Absinthe.Phase

  @spec run(Blueprint.t() | Phase.Error.t(), Keyword.t()) :: {:ok, map}
  def run(%Blueprint{} = bp, _options \\ []) do
    result = Map.merge(bp.result, process(bp))
    {:ok, %{bp | result: result}}
  end

  defp process(blueprint) do
    result =
      case blueprint.execution do
        %{validation_errors: [], result: result} ->
          ret = data(result, [])

          {:ok, ret}

        %{validation_errors: errors} ->
          {:validation_failed, errors}
      end

    format_result(result)
  end

  defp format_result({:ok, {data, []}}) do
    %{data: data}
  end

  defp format_result({:ok, {data, errors}}) do
    errors = errors |> Enum.uniq() |> Enum.map(&format_error/1)
    %{data: data, errors: errors}
  end

  defp format_result({:validation_failed, errors}) do
    errors = errors |> Enum.uniq() |> Enum.map(&format_error/1)
    %{errors: errors}
  end

  defp data(%{errors: [_ | _] = field_errors}, errors) do
    debug_log("data 1: data(%{errors: [_ | _] = field_errors}, errors)")
    {nil, field_errors ++ errors}
  end

  # Leaf
  defp data(%{value: nil}, errors) do
    debug_log("data 2: (%{value: nil}, errors)")
    # camelCase falls into this since value is not being set upstream
    {nil, errors}
  end

  defp data(%{value: value, emitter: emitter}, errors) do
    debug_log("data 3: (%{value: value, emitter: emitter}, errors)")
    # Change: don't serialize scalars
    value =
      case Type.unwrap(emitter.schema_node.type) do
        %Type.Scalar{} ->
          value

        %Type.Enum{} ->
          value
      end

    {value, errors}
  end

  # Object
  defp data(%{fields: []} = result, errors) do
    debug_log("data 4: (%{fields: []} = result, errors)")
    {result.root_value, errors}
  end

  defp data(%{fields: fields}, errors) do
    debug_log("data 5: (%{fields: fields, emitter: emitter, root_value: root_value}, errors)")

    case hd(fields) do
      %{errors: [_ | _] = field_errors} ->
        {nil, field_errors ++ errors}

      field ->
        selections =
          Enum.map(field.emitter.selections, fn %Absinthe.Blueprint.Document.Field{} = field ->
            field_name(field)
          end)

        values = Map.take(field.root_value, selections)

        out = Map.new([{field_name(field.emitter), values}])
        {out, []}
    end
  end

  # List
  defp data(%{values: values}, errors) do
    debug_log("data 6: (%{values: values}, errors)")
    list_data(values, errors)
  end

  defp list_data(fields, errors, acc \\ [])
  defp list_data([], errors, acc), do: {:lists.reverse(acc), errors}

  defp list_data([%{errors: errs} = field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    list_data(fields, errs ++ errors, [value | acc])
  end

  # TODO: would prefer if the names / aliases were already atoms somehow
  defp field_name(%{alias: nil, name: name}), do: String.to_atom(name)
  defp field_name(%{alias: name}), do: String.to_atom(name)
  defp field_name(%{name: name}), do: String.to_atom(name)

  defp format_error(%Phase.Error{locations: []} = error) do
    error_object = %{message: error.message}
    Map.merge(error.extra, error_object)
  end

  defp format_error(%Phase.Error{} = error) do
    error_object = %{
      message: error.message,
      locations: Enum.flat_map(error.locations, &format_location/1)
    }

    error_object =
      case error.path do
        [] -> error_object
        path -> Map.put(error_object, :path, path)
      end

    Map.merge(Map.new(error.extra), error_object)
  end

  defp format_location(%{line: line, column: col}) do
    [%{line: line || 0, column: col || 0}]
  end

  defp format_location(_), do: []

  defp debug_log(message) do
    if Application.get_env(:absinthe_remote, :should_log, false) do
      Logger.debug(message)
    end
  end
end
