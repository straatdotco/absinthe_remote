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
      posts(sorting: String, page: Int): [Message]
      children: [Message]
    }

    type Query {
      getMessage(search: MessageSearch, sorting: String): Message
      someIdQuery(someKey: ID): Message
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(_query, _operation, %{
          "someKey" => "1234"
        }) do
      {:ok,
       %{
         id: "1234"
       }}
    end

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

    def resolve_query(_query, _operation, %{"sorting" => "ASC"}) do
      {:ok,
       %{
         id: "1234",
         children: [
           %{
             id: "4321",
             posts: [
               %{
                 id: "4321-1"
               }
             ]
           }
         ]
       }}
    end

    def resolve_query(_query, _operation, %{"parentSorting" => parent, "childSorting" => child}) do
      {:ok,
       %{
         id: parent,
         posts: [
           %{
             id: child
           }
         ]
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

    assert AbsintheRemote.run(
             """
             query($someKey: ID) {
               someIdQuery(someKey: $someKey) {
                id
              }
             }
             """,
             LocalSchema,
             variables: %{
               "someKey" => "1234"
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   someIdQuery: %{
                     id: "1234"
                   }
                 }
               }
             }
  end

  test "can query child input types" do
    assert AbsintheRemote.run(
             """
             query($sorting: String, $page: Int) {
              getMessage {
                id
                children {
                  id
                  posts(sorting: $sorting, page: $page) {
                    id
                  }
                }
              }
             }
             """,
             LocalSchema,
             variables: %{
               "sorting" => "ASC",
               "page" => nil
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   getMessage: %{
                     id: "1234",
                     children: [
                       %{
                         id: "4321",
                         posts: [
                           %{
                             id: "4321-1"
                           }
                         ]
                       }
                     ]
                   }
                 }
               }
             }
  end

  test "handles aliased variables" do
    assert AbsintheRemote.run(
             """
             query($parentSorting: String, $childSorting: String) {
              getMessage(sorting: $parentSorting) {
                id
                posts(sorting: $childSorting) {
                  id
                }
              }
             }
             """,
             LocalSchema,
             variables: %{
               "parentSorting" => "ASC",
               "childSorting" => "DESC"
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   getMessage: %{
                     id: "ASC",
                     posts: [
                       %{
                         id: "DESC"
                       }
                     ]
                   }
                 }
               }
             }
  end
end
