defmodule Kvstore.MixProject do
  use Mix.Project

  def project do
    [
      app: :kvstore,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Kvstore, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.6"},
      {:plug, "~> 1.8.3"},
      {:plug_cowboy, "~> 2.1.0"},
    ]
  end
end
