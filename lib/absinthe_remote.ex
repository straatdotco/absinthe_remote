defmodule AbsintheRemote do
  @moduledoc """
  Documentation for `AbsintheRemote`.
  """
  alias Absinthe.{Pipeline, Phase}

  def run(document, schema, options \\ []) do
    options = Keyword.put(options, :pipeline_modifier, &custom_pipeline/2)
    # options = Keyword.put(options, :adapter, WTF)

    Absinthe.run(
      document,
      schema,
      options
    )
  end

  def run!(document, schema, options \\ []) do
    options = Keyword.put(options, :pipeline_modifier, &custom_pipeline/2)
    # options = Keyword.put(options, :adapter, WTF)

    Absinthe.run!(
      document,
      schema,
      options
    )
  end

  defp custom_pipeline(pipeline, options) do
    pipeline
    |> Absinthe.Pipeline.replace(
      Absinthe.Phase.Document.Execution.Resolution,
      {AbsintheRemote.RemoteResolution, []}
    )
    |> Pipeline.insert_after(
      Phase.Document.Directives,
      {AbsintheRemote.ResultPhase, options}
    )
  end
end

defmodule WTF do
  use Absinthe.Adapter

  def to_internal_name(external_name, _role) do
    String.upcase(external_name)
  end

  def to_external_name(internal_name, _role) do
    String.upcase(internal_name)
  end
end
