defmodule Narasihistorian.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :category_name, :string
      add :slug, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:slug])
    create unique_index(:categories, [:category_name])
  end
end
