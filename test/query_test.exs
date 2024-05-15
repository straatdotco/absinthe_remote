defmodule AbsintheRemote.QueryTest do
  use ExUnit.Case, async: true

  defmodule LocalSchema do
    use AbsintheRemote.RemoteSchema

    import_sdl("""
    type SomeParent {
      id: ID
      name: String
      some_int: Int
      child: SomeChild
    }

    type SomeChild {
      id: ID
      foo: String
    }

    type SomeOperation {
      name: String
    }

    type Query {
      parent(id: ID!): SomeParent
      child(id: ID!): SomeChild
      optional(id: ID): SomeParent
      operation: SomeOperation
    }
    """)

    @impl AbsintheRemote.RemoteSchema
    def resolve_query(_query, "SomeError", _variables) do
      {:error, "Some error string"}
    end

    def resolve_query(_query, "ChildQuery", _variables) do
      {:ok,
       %{
         id: "4321",
         foo: "bar"
       }}
    end

    def resolve_query(_query, _operation, _variables) do
      {:ok,
       %{
         id: "1234",
         name: "parent",
         some_int: 567,
         child: %{
           id: "4321",
           foo: "bar"
         }
       }}
    end
  end

  test "validates against local schema" do
    assert AbsintheRemote.run(
             """
             query {
              parent {
                nonexistant_field
              }
             }
             """,
             LocalSchema
           ) ==
             {
               :ok,
               %{
                 errors: [
                   %{
                     locations: [%{column: 4, line: 3}],
                     message: "Cannot query field \"nonexistant_field\" on type \"SomeParent\"."
                   },
                   %{
                     locations: [%{column: 2, line: 2}],
                     message: "In argument \"id\": Expected type \"ID!\", found null."
                   }
                 ]
               }
             }
  end

  test "handles query errors" do
    assert AbsintheRemote.run(
             """
             query SomeError {
               parent(id: 1) {
                 id
               }
             }
             """,
             LocalSchema
           ) ==
             {:ok,
              %{
                data: nil,
                errors: [
                  %{
                    locations: [%{column: 3, line: 2}],
                    message: "Some error string",
                    path: ["parent"]
                  }
                ]
              }}
  end

  test "remote query resolution" do
    assert AbsintheRemote.run(
             """
             query($id: ID!) {
              parent(id: $id) {
                id
                name
                some_int

                child {
                  id
                  foo
                }
              }
             }
             """,
             LocalSchema,
             variables: %{"id" => 1}
           ) ==
             {:ok,
              %{
                data: %{
                  parent: %{
                    id: "1234",
                    name: "parent",
                    some_int: 567,
                    child: %{
                      id: "4321",
                      foo: "bar"
                    }
                  }
                }
              }}
  end

  test "supports multiple queries" do
    single_query = """
    query ParentQuery {
      parent(id: 1) {
        id
      }
    }
    query ChildQuery {
      child(id: 1) {
        id
      }
    }
    """

    assert AbsintheRemote.run(
             single_query,
             LocalSchema,
             operation_name: "ChildQuery"
           ) == {:ok, %{data: %{child: %{id: "4321"}}}}

    assert AbsintheRemote.run(
             single_query,
             LocalSchema,
             operation_name: "ParentQuery"
           ) == {:ok, %{data: %{parent: %{id: "1234"}}}}
  end

  test "allows nullable query parameters" do
    assert AbsintheRemote.run(
             """
             query($id: ID) {
              optional(id: $id) {
                id
              }
             }
             """,
             LocalSchema,
             variables: %{"id" => nil}
           ) ==
             {:ok,
              %{
                data: %{
                  optional: %{
                    id: "1234"
                  }
                }
              }}
  end
end
