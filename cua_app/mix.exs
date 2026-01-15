defmodule CuaApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :cua_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CuaApp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:anthropix, "~> 0.6"},
      {:anthropix, path: "./deps/anthropix"},
      {:jason, "~> 1.4"},
      {:dotenvy, "~> 0.8.0"},
      {:browserbase_api, path: "../../browserbase_ex"}
    ]
  end
end
