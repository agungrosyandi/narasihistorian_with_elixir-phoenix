defmodule Narasihistorian.Drafts.Draft do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drafts" do
    # "category" | "article"
    field :draft_type, :string
    # "new" | "edit"
    field :action, :string
    # nil for :new, category/article id for :edit
    field :ref_id, :integer
    # %{"category_name" => "...", "description" => "..."}
    field :data, :map
    field :status, :string, default: "pending"

    belongs_to :user, Narasihistorian.Accounts.User

    timestamps()
  end

  def changeset(draft, attrs) do
    draft
    |> cast(attrs, [:user_id, :draft_type, :action, :ref_id, :data, :status])
    |> validate_required([:user_id, :draft_type, :action, :data])
    |> validate_inclusion(:draft_type, ["category", "article"])
    |> validate_inclusion(:action, ["new", "edit"])
    |> validate_inclusion(:status, ["pending", "published"])
  end
end
