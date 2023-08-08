# AbsintheRemote

A library for helping you run GraphQL queries against remote GraphQL servers, with the client protections of Absinthe.

## Installation

The package can be installed
by adding `absinthe_remote` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_remote, "~> 0.1.0"}
  ]
end
```

## Quick Start
Define a remote schema:
```elixir
defmodule MyRemoteSchema do
  use AbsintheRemote.RemoteSchema

  import_sdl("""
  type SomeOperation {
    name: String
  }

  type Query {
    operation: SomeOperation
  }
  """)

  @impl AbsintheRemote.RemoteSchema
  def resolve_query(query, operation_name, variables) do

    case MyGraphClientOrHttpClient.run(query, operation_name, variables) do
      {:ok, data} ->
        {:ok, data}
      {:error, message} -> 
        {:error, message}
    end
  end
end
```

then utilize your Remote Schema to run a query:
```elixir
AbsintheRemote.run("""
  query {
    operation {
      name
    }
  }
""", MyRemoteSchema) == {:ok, %{name: "hello world"}}
```
