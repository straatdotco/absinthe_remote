defmodule AbsintheRemote.InputTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    enum AuthorType {
      ADMIN
      USER
    }

    input MessageSearch {
      content: String
      authorName: String
      authorType: AuthorType
    }

    type Message {
      id: ID!
      content: String
      author: String
      posts(sorting: String): [Message]
      children: [Message]
      author_type: AuthorType
    }

    type Query {
      getMessage(search: MessageSearch, sorting: String): Message
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

    def resolve_query(_query, _operation, %{"search" => %{"authorType" => "ADMIN"}}) do
      {:ok,
       %{
         id: "1234",
         author: "Foo Bar",
         authorType: "ADMIN"
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

  test "can query child input types" do
    assert AbsintheRemote.run(
             """
             query($sorting: String) {
              getMessage {
                id
                children {
                  id
                  posts(sorting: $sorting) {
                    id
                  }
                }
              }
             }
             """,
             LocalSchema,
             variables: %{
               "sorting" => "ASC"
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

  test "handles enums correctly" do
    assert AbsintheRemote.run(
             """
             query($search: MessageSearch) {
              getMessage(search: $search) {
                id
                author
                authorType
              }
             }
             """,
             LocalSchema,
             variables: %{
               "search" => %{
                 "authorType" => "ADMIN"
               }
             }
           ) ==
             {
               :ok,
               %{
                 data: %{
                   getMessage: %{
                     id: "1234",
                     author: "Foo Bar",
                     authorType: "ADMIN"
                   }
                 }
               }
             }
  end
end
