defmodule AbsintheRemote.InputTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    input MessageSearch {
      content: String
      authorName: String
    }

    type Message {
      id: ID!
      content: String
      author: String
    }

    type Query {
      getMessage(search: MessageSearch): Message
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(_query, _operation, %{
          "search" => %{"authorName" => author_name, "content" => content}
        }) do
      # Sends out the variables we send it instead of fake daat

      {:ok,
       %{
         id: "1234",
         content: content,
         author: author_name
       }}
    end
  end

  test "can query input types" do
    assert AbsintheRemote.run(
             """
             query($search: MessageSearch) {
              getMessage(search: $search) {
                id
                content
                author
              }
             }
             """,
             LocalSchema,
             variables: %{
               "search" => %{
                 "authorName" => "Mr Foo Bar",
                 "content" => "Hello"
               }
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   getMessage: %{
                     id: "1234",
                     content: "Hello",
                     author: "Mr Foo Bar"
                   }
                 }
               }
             }
  end
end
