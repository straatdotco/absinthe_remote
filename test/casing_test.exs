defmodule AbsintheRemote.CasingTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    type Message {
      id: ID!
      content: String
      authorName: String
      author_age: Int
    }

    type Query {
      getMessage(id: ID!): Message
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(_query, _operation, _variables) do
      {:ok,
       %{
         id: "1234",
         content: "Hello world!",
         authorName: "Mr Foo Bar",
         author_age: 32
       }}
    end
  end

  test "handles various field casing" do
    assert AbsintheRemote.run(
             """
             query($id: ID!) {
              getMessage(id: $id) {
                id
                content
                authorName
                author_age
              }
             }
             """,
             LocalSchema,
             variables: %{
               "id" => 1234
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   getMessage: %{
                     id: "1234",
                     content: "Hello world!",
                     authorName: "Mr Foo Bar",
                     author_age: 32
                   }
                 }
               }
             }
  end
end
