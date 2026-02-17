defmodule Narasihistorian.AccountsFixtures do
  import Ecto.Query

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_username, do: "user#{System.unique_integer([:positive])}"
  def valid_user_password, do: "HelloWorld123!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: unique_username(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        username: unique_username(),
        password: valid_user_password()
      })
      |> Narasihistorian.Accounts.register_user()

    user
  end

  # ← ADD THIS
  def admin_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    Narasihistorian.Repo.update_all(
      from(u in Narasihistorian.Accounts.User, where: u.id == ^user.id),
      set: [role: :admin]
    )

    Narasihistorian.Repo.get!(Narasihistorian.Accounts.User, user.id)
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
