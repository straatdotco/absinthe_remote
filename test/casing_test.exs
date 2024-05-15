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
      all_messages: [Message]
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(_query, "AllMessages", _variables) do
      {:ok,
       %{
         all_messages: [
           %{
             id: "1234",
             content: "Hello world!",
             authorName: "Mr Foo Bar",
             author_age: 32
           }
         ]
       }}
    end

    def resolve_query(_query, _operation, _variables) do
      {:ok,
       %{
         getMessage: %{
           id: "1234",
           content: "Hello world!",
           authorName: "Mr Foo Bar",
           author_age: 32
         }
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

  # test "handles various query casing" do
  #   assert AbsintheRemote.run(
  #            """
  #            query AllMessages {
  #             all_messages {
  #               id
  #             }
  #            }
  #            """,
  #            LocalSchema
  #          ) ==
  #            {
  #              :ok,
  #              %{
  #                data: %{
  #                  all_messages: [
  #                    %{
  #                      id: "1234"
  #                    }
  #                  ]
  #                }
  #              }
  #            }
  # end
end
