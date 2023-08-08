defmodule AbsintheRemote.ResultPhase do
  @moduledoc """
  Swaps out Absinthe.Phase.Document.Result for our own AbsintheRemote.Result
  """

  @behaviour Absinthe.Phase

  alias Absinthe.Phase

  @impl Absinthe.Phase
  def run(bp, _opts) do
    {:swap, bp, Phase.Document.Result, AbsintheRemote.Result}
  end
end
