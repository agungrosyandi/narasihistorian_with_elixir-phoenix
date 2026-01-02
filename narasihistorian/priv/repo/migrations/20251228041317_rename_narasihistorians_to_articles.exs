defmodule Narasihistorian.Repo.Migrations.RenameNarasihistoriansToArticles do
  use Ecto.Migration

  def change do
    rename table(:narasihistorians), to: table(:articles)
  end
end
