defmodule Mix.Tasks.ListProjects do
  use Mix.Task

  @shortdoc "Run task that list all projects from toggl"
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)
    :ok = Application.ensure_started(:tzdata)
    SillyTurtle.CLI.main
  end

end
