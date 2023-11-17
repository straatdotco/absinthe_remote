defmodule AbsintheRemote.RemoteSchema do
  @callback resolve_query(
              query :: binary(),
              operation_name :: binary(),
              variables :: map()
            ) ::
              {:ok, data :: map()} | {:error, reason :: term}
  defmacro __using__(_opts) do
    quote do
      use Absinthe.Schema

      @behaviour AbsintheRemote.RemoteSchema

      def hydrate(%Absinthe.Blueprint.Schema.FieldDefinition{identifier: query}, [
            %Absinthe.Blueprint.Schema.ObjectTypeDefinition{identifier: query_type} | _
          ])
          when query_type in [:query, :mutation] do
        case Atom.to_string(query) do
          "__" <> _internal ->
            # If this is an internal query (__type, __schema, etc), let it do its thing
            []

          _ ->
            {:resolve, &__MODULE__.get_value/3}
        end
      end

      def hydrate(_node, _ancestors) do
        []
      end

      def get_value(one, variables, %Absinthe.Resolution{definition: query} = resolution) do
        query_variables =
          Enum.map(query.arguments, &argument_to_query_variable/1) |> Enum.into(%{})

        selection_variables =
          selections_to_query_variables(query.selections, [])
          |> List.flatten()
          |> Enum.into(%{})

        variables = Map.merge(query_variables, selection_variables)

        case resolve_query(
               resolution.private.raw_source,
               resolution.private.operation_name,
               variables
             ) do
          {:ok, result} when is_map(result) ->
            # pop the value out of the inner struct,
            # of if it doesn't exist, just use the result
            {:ok, Map.get(result, String.to_atom(query.name), result)}

          {:ok, result} ->
            {:ok, result}

          other ->
            other
        end
      end

      defp selections_to_query_variables(
             [%Absinthe.Blueprint.Document.Field{selections: []} = field | tail],
             acc
           ) do
        selections_to_query_variables(
          tail,
          acc ++ Enum.map(field.arguments, &argument_to_query_variable/1)
        )
      end

      defp selections_to_query_variables(
             [%Absinthe.Blueprint.Document.Field{selections: selections} = field | tail],
             acc
           ) do
        # Recurse!
        selections_to_query_variables(
          tail,
          acc ++
            Enum.map(field.arguments, &argument_to_query_variable/1) ++
            selections_to_query_variables(selections, [])
        )
      end

      defp selections_to_query_variables([], acc) do
        acc
      end

      defp flatten_errors([%{"message" => message} | rest], acc) do
        flatten_errors(rest, acc ++ [message])
      end

      defp flatten_errors(_, acc), do: acc

      defp keys_to_atoms(string_key_map) when is_map(string_key_map) do
        for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), keys_to_atoms(val)}
      end

      defp keys_to_atoms(value), do: value

      defp argument_to_query_variable(%Absinthe.Blueprint.Input.Argument{} = arg) do
        # Important to use the normalized fields because they are what the schema actually calls for
        key = fetch_key(arg)
        value = fetch_normalized_value(arg.input_value.normalized)

        if key do
          {key, value}
        else
          {value}
        end
      end

      defp fetch_key(%Absinthe.Blueprint.Input.Argument{
             input_value: %Absinthe.Blueprint.Input.Value{
               raw: %Absinthe.Blueprint.Input.RawValue{
                 content: %Absinthe.Blueprint.Input.Variable{name: name}
               }
             }
           }),
           do: name

      defp fetch_key(%Absinthe.Blueprint.Input.Argument{name: name}), do: name

      defp fetch_normalized_value(%Absinthe.Blueprint.Input.Object{} = obj) do
        # Since this is an object, we need to recurse a bit
        obj.fields
        |> Enum.map(fn %Absinthe.Blueprint.Input.Field{} = field ->
          {field.name, fetch_normalized_value(field.input_value.normalized)}
        end)
        |> Enum.into(%{})
      end

      defp fetch_normalized_value(%Absinthe.Blueprint.Input.Null{}), do: nil

      defp fetch_normalized_value(some_input) do
        if is_map(some_input) and Map.has_key?(some_input, :value) do
          some_input.value
        else
          raise "Unknown input type #{inspect(some_input)}"
        end
      end
    end
  end
end
