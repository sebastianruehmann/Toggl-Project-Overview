defmodule SillyTurtle.CLI do
  alias TableRex.Table

  @baseurl "https://www.toggl.com/api/v8"
  @username "TOGGL_USERNAME"
  @workspace_id "TOGGL_WORKSPACE_ID"
  @password "TOGGL_PASSWORD"
  # days in the past
  @from 30

  def main() do
    get_workspace_projects(@workspace_id)
    |> populate
    |> sort
    |> filter
    |> render(["Project", "Client", "Last tracked Task", "Total Time"], "What happenend in the last 30 days?")
    |> IO.puts
  end

  defp render(rows, header, title) do
    Table.new(rows, header, title)
    |> Table.put_column_meta(:all, align: :left, padding: 0) # `0` is the column index.
    |> Table.render!
  end

  defp auth_header(username, password) do
    encoded = Base.encode64("#{username}:#{password}")
    ["Authorization": "Basic #{encoded}", "Accept": "Application/json; Charset=utf-8"]
  end

  defp ssl_handshake() do
    [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
  end

  defp get_workspace_projects(workspace_id) do
    fetch_toggl_data("/workspaces/" <> workspace_id <> "/projects")
  end

  defp populate(projects) do
    time_entries = get_time_entries()
    Enum.map(projects, fn(x) -> add_project_clients(x) end)
    |> Enum.map(fn(x) -> add_time_entries(x, time_entries) end)
  end

  defp add_project_clients(project) do
    Map.put(project, "client", get_client_data(project["cid"])["data"])
  end

  defp add_time_entries(project, time_entries) do
    Map.put(project, "time_entries", time_entries[project["id"]])
  end

  defp get_time_entries() do
    start_date = Timex.now |> Timex.shift(days: -@from) |> DateTime.to_iso8601
    end_date = Timex.now |> DateTime.to_iso8601
    fetch_toggl_data("/time_entries?end_date=#{end_date}&start_date=#{start_date}")
    |> Enum.group_by(fn(x) -> x["pid"] end)
  end

  defp get_client_data(client_id) when client_id != nil do
    fetch_toggl_data("/clients/" <> Integer.to_string(client_id))
  end

  defp get_client_data(_) do nil end

  defp fetch_toggl_data(endpoint) do
    response = HTTPoison.get(@baseurl <> endpoint, auth_header(@username, @password), ssl_handshake())
    |> handle_result
    case response do
      {:ok, value} -> value
      {:error, reason} -> exit("Uh oh! Failed due to: #{reason}.")
    end
  end

  defp handle_result({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, body |> Poison.decode!}
  end

  defp handle_result({:ok, %HTTPoison.Response{status_code: 404}}) do
    {:error, "API Endpoint not found"}
  end

  defp handle_result({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "HTTP Error: #{{reason}}"}
  end

  defp handle_result({}) do
    {:error, "Unknown Error"}
  end

  defp sort(projects) do
    Enum.sort(projects, &order_asc_by_time(&1,&2))
  end

  defp order_asc_by_time(i,j) do
    i["actual_hours"] < j["actual_hours"]
  end

  defp filter(projects) do
    Enum.map(projects, &format_rows/1)
  end

  defp format_rows(project) do
    [
      project["name"],
      format_client_name(project["client"]),
      format_time_entry(project["time_entries"]),
      format_hours(project["actual_hours"])
    ]
  end

  defp format_hours(hours) when hours != nil do
    to_string(hours) <> "h"
  end

  defp format_hours(_) do
    "0h"
  end

  defp format_time_entry(time_entry) when time_entry != nil do
    Enum.at(time_entry, Enum.count(time_entry) - 1)
    |> Map.get("description")
  end

  defp format_time_entry(_) do
    "😴"
  end

  defp format_client_name(%{"name" => client_name}) do
    client_name
  end

  defp format_client_name(_) do
    Enum.random(["🤠","🤡","🤖","👨🏿","👮🏻"])
  end
end
