defmodule Narasihistorian.Repo.Migrations.AddImageCategoryAndDescription do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :description, :string
      add :image_category, :string
    end
  end
end
