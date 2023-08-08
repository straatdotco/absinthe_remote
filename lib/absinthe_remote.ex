defmodule AbsintheRemote do
  @moduledoc """
  Documentation for `AbsintheRemote`.
  """
  alias Absinthe.{Pipeline, Phase}

  def run(document, schema, options \\ []) do
    options = Keyword.put(options, :pipeline_modifier, &custom_pipeline/2)

    Absinthe.run(
      document,
      schema,
      options
    )
  end

  def run!(document, schema, options \\ []) do
    options = Keyword.put(options, :pipeline_modifier, &custom_pipeline/2)

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
