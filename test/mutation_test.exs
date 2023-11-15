defmodule AbsintheRemote.MutationTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    input MessageInput {
      content: String
      author: String
    }

    type Message {
      id: ID!
      content: String
      author: String
    }

    type Query {
      getMessage(id: ID!): Message
    }

    type Mutation {
      createMessage(input: MessageInput): Message
      updateMessage(id: ID!, input: MessageInput): Message
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(
          _query,
          _operation,
          %{
            "input" => %{"author" => author, "content" => content}
          }
        ) do
      {:ok,
       %{
         id: "1",
         author: author,
         content: content
       }}
    end
  end

  test "can use mutations" do
    assert AbsintheRemote.run(
             """
             mutation($input: MessageInput) {
              createMessage(input: $input) {
                id
                content
                author
              }
             }
             """,
             LocalSchema,
             variables: %{
               "input" => %{
                 "author" => "Mr Foo Bar",
                 "content" => "Hello world!"
               }
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   createMessage: %{
                     id: "1",
                     content: "Hello world!",
                     author: "Mr Foo Bar"
                   }
                 }
               }
             }
  end
end
