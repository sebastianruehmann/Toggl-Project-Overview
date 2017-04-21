defmodule SillyTurtle.Mixfile do
  use Mix.Project

  def project do
    [app: :sillyturtle,
     version: "0.1.0",
     elixir: "~> 1.4",
     escript: escript_config(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(), default_task: "list_projects"]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [mod: {SillyTurtle.CLI, []},
    applications: [:logger, :timex, :httpoison, :poison, :table_rex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.10.0"},
      {:poison, "~> 3.0"},
      {:table_rex, "~> 0.10"},
      {:timex, "~> 3.0"},
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end

  defp escript_config do
    [main_module: SillyTurtle.CLI]
  end
end
