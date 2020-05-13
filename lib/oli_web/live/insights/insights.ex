defmodule OliWeb.Insights do
  use Phoenix.LiveView

  import Ecto.Query, warn: false

  alias Oli.Repo
  alias Phoenix.PubSub
  alias Oli.Delivery.Attempts.Snapshot
  alias OliWeb.Insights.TableRow

  def mount(_params, %{ "project_id" => project_id } = _session, socket) do

    # PubSub.subscribe Oli.PubSub, "resource:" <> Integer.to_string(resource_id)

    # revisions = Repo.all(from rev in Revision,
    #   where: rev.resource_id == ^resource_id,
    #   order_by: [desc: rev.inserted_at],
    #   select: rev)

    # selected = hd(revisions)

    # {:ok, assign(socket,
    #   resource_id: resource_id,
    #   revisions: revisions,
    #   selected: selected,
    #   initial_size: length(revisions))
    # }

    # For each skill (in what?)
    #   Table
    #   Question text (with link)...  Number of attempts  Relative difficulty Eventually Correct  First Try Correct
    # number of attempts: sum()
    # Relative difficulty: (# hints requested + # incorrect answers) / total attempts
    # Eventually correct:
    # First try correct:
    # <%= live_component @socket, Graph, revisions: reversed, selected: @selected, initial_size: @initial_size %>
    # <%= live_component @socket, Details, revision: @selected %>

    # "eventually correct"
    #   private void addCompletionRate(JsonObject result) {
    #     // Completion rate = correct / practice
    #     Double correct = result.get("correct").getAsDouble();
    #     Double practice = result.get("practice").getAsDouble();
    #     Double completionRate = 0.0;

    #     if (!Double.isNaN(correct) && !Double.isNaN(practice) && practice > 0) {
    #         completionRate = correct / practice;
    #     }
    #     result.addProperty("completionRate", completionRate);
    # }
    # "first try correct"
    #   private void addAccuracyRate(JsonObject result) {
    #     // Accuracy rate = first response correct / practice
    #     Double firstResponseCorrect = result.get("firstResponseCorrect").getAsDouble();
    #     Double practice = result.get("practice").getAsDouble();
    #     Double accuracyRate = 0.0;

    #     if (!Double.isNaN(firstResponseCorrect) && !Double.isNaN(practice) && practice > 0) {
    #         accuracyRate = firstResponseCorrect / practice;
    #     }
    #     result.addProperty("accuracyRate", accuracyRate);
    # }


    # need separate snapshots for each "by" option. Send selected snapshots to component
    # Questions:
    #   What should the queries look like? Not yet sure how to get the right data from the snapshots table
    #     A little confused about how the ecto query language works with sub-queries and sql fragments. Best option?
    #   How to handle "by skills" when the objectives are listed as an array? What's the best way to handle this?
    #   What should links point to for each of the rows? For an activity, what do we link to?
    #      A page with the activity in edit mode?
    #   How to test queries with no real datasets?


    # number of attempts
    # Relative difficulty: (# hints requested + # incorrect answers) / total attempts
    # Eventually correct:
    # First try correct:

    # by activity

    by_page_snapshots = []
    by_skill_snapshots = []
    by_activity_snapshots = Oli.Analytics.ByActivity.combined_query(project_id)

    {:ok, assign(socket,
      by_page_rows: by_page_snapshots,
      by_activity_rows: by_activity_snapshots,
      by_skill_rows: by_skill_snapshots,
      selected: :by_activity
    )}
  end

  def render(assigns) do

    ~L"""
    <div class="card text-center">
      <div class="card-header">
        <ul class="nav nav-tabs card-header-tabs">
          <li class="nav-item">
            <button class="btn btn-primary" phx-click="by-page">By Page</button>
          </li>
          <li class="nav-item">
            <button class="btn btn-primary" phx-click="by-activity">By Activity</button>
          </li>
          <li class="nav-item">
            <button class="btn btn-primary" phx-click="by-skill">By Skill</button>
          </li>
        </ul>
      </div>
      <div class="card-body">
        <h5 class="card-title">
          <%= case assigns.selected do
          :by_page -> "View analytics by page"
          :by_activity -> "View analytics by activity"
          :by_skill -> "View analytics by skill"
          _ -> "View analytics by activity"
        end %></h5>
        <table class="table">
          <thead>
            <tr>
              <th scope="col">
                <%= case assigns.selected do
                  :by_page -> "Page"
                  :by_activity -> "Activity"
                  :by_skill -> "Skill"
                  _ -> "Skill"
                end %>
                </th>
              <th scope="col">Number of Attempts</th>
              <th scope="col">Relative Difficulty</th>
              <th scope="col">Eventually Correct</th>
              <th scope="col">First Try Correct</th>
            </tr>
          </thead>
          <tbody>
            <%= for {row, i} <- Enum.with_index(
              case assigns.selected do
                :by_page -> assigns.by_page_rows
                :by_activity -> assigns.by_activity_rows
                :by_skill -> assigns.by_skill_rows
                _ -> assigns.by_activity_rows
              end) do %>
            <%= live_component @socket, TableRow,
              index: i,
              row: row %>
            <% end %>
            <tr>
              <th scope="row">Activity 1 text with link</th>
              <td>Mark</td>
              <td>Otto</td>
              <td>@mdo</td>
              <td>@mdo</td>
            </tr>
            <tr>
              <th scope="row">Activity 2 text with link</th>
              <td>Jacob</td>
              <td>Thornton</td>
              <td>@fat</td>
              <td>@fat</td>
            </tr>
            <tr>
              <th scope="row">Activity 3 text with link</th>
              <td>Larry</td>
              <td>the Bird</td>
              <td>@twitter</td>
              <td>@twitter</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def handle_event("by-activity", _event, socket) do
    {:noreply, assign(socket, :selected, :by_activity)}
  end

  def handle_event("by-page", _event, socket) do
    {:noreply, assign(socket, :selected, :by_page)}
  end

  def handle_event("by-skill", _event, socket) do
    {:noreply, assign(socket, :selected, :by_skill)}
  end

end
