defmodule Narasihistorian.Repo.Migrations.AddRolesToUsers do
  use Ecto.Migration

  def up do
    # Create the enum type first

    execute "CREATE TYPE user_role AS ENUM ('user', 'admin')"

    # Add role column to users table

    alter table(:users) do
      add :role, :user_role, default: "user", null: false
    end

    # Index for querying by role

    create index(:users, [:role])
  end

  def down do
    # Remove index first

    drop index(:users, [:role])

    # Remove the column

    alter table(:users) do
      remove :role
    end

    # Drop the enum type last

    execute "DROP TYPE user_role"
  end
end
