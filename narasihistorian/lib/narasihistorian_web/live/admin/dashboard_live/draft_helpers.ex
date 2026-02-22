defmodule NarasihistorianWeb.Admin.DashboardLive.DraftHelpers do
  def draft_title(draft) do
    case draft.data do
      %{"category_name" => name} when is_binary(name) and name != "" -> name
      %{"title" => title} when is_binary(title) and title != "" -> title
      _ -> "(Tanpa judul)"
    end
  end

  def draft_path(%{draft_type: "category", action: "new", id: id}),
    do: "/admin/categories/new?draft_id=#{id}"

  def draft_path(%{draft_type: "category", action: "edit", ref_id: ref_id, id: id}),
    do: "/admin/categories/#{ref_id}/edit?draft_id=#{id}"

  def draft_path(%{draft_type: "article", action: "new", id: id}),
    do: "/admin/articles/new?draft_id=#{id}"

  def draft_path(%{draft_type: "article", action: "edit", ref_id: ref_id, id: id}),
    do: "/admin/articles/#{ref_id}/edit?draft_id=#{id}"

  def time_ago(datetime) do
    utc =
      case datetime do
        %DateTime{} = dt -> dt
        %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
      end

    diff = DateTime.diff(DateTime.utc_now(), utc, :second)

    cond do
      diff < 60 -> "Baru saja"
      diff < 3600 -> "#{div(diff, 60)} menit lalu"
      diff < 86400 -> "#{div(diff, 3600)} jam lalu"
      true -> "#{div(diff, 86400)} hari lalu"
    end
  end
end
