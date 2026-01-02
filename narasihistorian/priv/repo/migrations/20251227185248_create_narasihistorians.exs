defmodule Narasihistorian.Repo.Migrations.CreateNarasihistorians do
  use Ecto.Migration

  def change do
    create table(:narasihistorians) do
      add :article_name, :string
      add :article_description, :text
      add :image, :string

      timestamps(type: :utc_datetime)
    end
  end
end
