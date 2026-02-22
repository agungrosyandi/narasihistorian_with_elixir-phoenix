defmodule Narasihistorian.Drafts do
  @moduledoc """
  Context for managing drafts.
  Drafts are auto-saved form data that persists across sessions.
  They are deleted when the real record is created/updated.
  """

  import Ecto.Query
  alias Narasihistorian.Repo
  alias Narasihistorian.Drafts.Draft

  # ============================================================================
  # READ
  # ============================================================================

  @doc """
  Returns all drafts for the dashboard (all users, all types).
  Preloads the user association.
  """

  def list_all_drafts do
    Draft
    |> order_by([d], desc: d.updated_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Returns all drafts for a specific user.
  """

  def list_drafts_by_user(user_id) do
    Draft
    |> where([d], d.user_id == ^user_id)
    |> order_by([d], desc: d.updated_at)
    |> Repo.all()
  end

  @doc """
  Returns drafts for a specific user and type (e.g. "category").
  Used for the small indicator on the index page.
  """

  def list_drafts_by_user_and_type(user_id, draft_type) do
    Draft
    |> where([d], d.user_id == ^user_id and d.draft_type == ^draft_type)
    |> order_by([d], desc: d.updated_at)
    |> Repo.all()
  end

  @doc """
  Gets a single draft by its id. Returns nil if not found.
  Used by FormComponent when loading from ?draft_id= URL param.
  """

  def get_draft_by_id(id) do
    Repo.get(Draft, id)
  end

  @doc """
  Gets a single draft by its id. Returns nil if not found.
  """

  def get_draft(user_id, draft_type, action, ref_id) do
    Draft
    |> where(
      [d],
      d.user_id == ^user_id and
        d.draft_type == ^draft_type and
        d.action == ^action
    )
    |> then(fn query ->
      if is_nil(ref_id) do
        where(query, [d], is_nil(d.ref_id))
      else
        where(query, [d], d.ref_id == ^ref_id)
      end
    end)
    |> Repo.one()
  end

  @doc """
  Counts pending drafts for a user and type.
  Used for the indicator badge.
  """

  def count_drafts(user_id, draft_type) do
    Draft
    |> where([d], d.user_id == ^user_id and d.draft_type == ^draft_type)
    |> select([d], count(d.id))
    |> Repo.one()
  end

  # ============================================================================
  # WRITE
  # ============================================================================

  @doc """
  Upserts a draft — creates it if it doesn't exist, updates if it does.
  Called when the user closes the modal.

  ## Examples
      upsert_draft(user, "category", "new", nil, %{"category_name" => "foo"})
      upsert_draft(user, "category", "edit", 5, %{"category_name" => "bar"})
  """

  def upsert_draft(user, draft_type, action, ref_id, data) do
    case get_draft(user.id, draft_type, action, ref_id) do
      nil ->
        %Draft{}
        |> Draft.changeset(%{
          user_id: user.id,
          draft_type: draft_type,
          action: action,
          ref_id: ref_id,
          data: data,
          status: "pending"
        })
        |> Repo.insert()

      existing ->
        existing
        |> Draft.changeset(%{data: data})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a draft for a specific context.
  Called when the real record is successfully created/updated.
  """

  def delete_draft(user_id, draft_type, action, ref_id) do
    case get_draft(user_id, draft_type, action, ref_id) do
      nil -> :ok
      draft -> Repo.delete(draft)
    end
  end

  @doc """
  Deletes a draft by id.
  Used from the dashboard to manually discard a draft.
  """

  def delete_draft_by_id(id) do
    case Repo.get(Draft, id) do
      nil -> {:error, :not_found}
      draft -> Repo.delete(draft)
    end
  end

  # Count all drafts for a user across all types

  def count_all_drafts(user_id) do
    Draft
    |> where([d], d.user_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end

  # List all drafts for a specific user (instead of all users)

  def list_all_drafts_for_user(user_id) do
    Draft
    |> where([d], d.user_id == ^user_id)
    |> order_by([d], desc: d.updated_at)
    |> Repo.all()
  end
end
