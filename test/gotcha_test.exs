defmodule AbsintheRemote.GotchaTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    type TypingTypes {
      regular: ID
      camelCase: String
      snake_case: Int
    }

    type Query {
      types: TypingTypes
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(query, operation, variables) do
      {:ok,
       %{
         regular: "1234",
         camelCase: "5y",
         snake_case: 5
       }}
    end
  end

  test "can query input types" do
    assert AbsintheRemote.run(
             """
             query {
              types {
                regular
                camelCase
                snake_case
              }
             }
             """,
             LocalSchema
           ) ==
             {
               :ok,
               %{
                 data: %{
                   types: %{
                     regular: "1234",
                     camelCase: "5y",
                     snake_case: 5
                   }
                 }
               }
             }
  end
end
