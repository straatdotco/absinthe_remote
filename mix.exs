defmodule AbsintheRemote.MixProject do
  use Mix.Project

  @source_url "https://github.com/straatdotco/absinthe_remote"
  @version "0.1.1"

  def project do
    [
      app: :absinthe_remote,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      name: "Absinthe Remote",
      source_url: @source_url,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:absinthe, "~> 1.7"}
    ]
  end

  defp description do
    "A library for helping you run GraphQL queries against remote GraphQL servers, with the client protections of Absinthe."
  end

  defp package do
    [
      description: description(),
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Luke Strickland"
      ],
      licenses: ["MIT"],
      links: %{
        Website: "https://github.com/straatdotco/absinthe_remote",
        Changelog: "#{@source_url}/blob/master/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end
end
