defmodule Narasihistorian.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # ============================================================================
  # SCHEMA
  # ============================================================================

  @valid_roles [:user, :admin]

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :role, Ecto.Enum, values: @valid_roles, default: :user

    # OAuth fields

    field :provider, :string
    field :provider_uid, :string
    field :provider_token, :string
    field :provider_refresh_token, :string
    field :provider_expires_at, :utc_datetime
    field :avatar_url, :string

    has_many :comments, Narasihistorian.Comments.Comment
    has_many :articles, Narasihistorian.Articles.Article
    has_many :categories, Narasihistorian.Categories.Category

    timestamps(type: :utc_datetime)
  end

  # ============================================================================
  # CHANGESET
  # ============================================================================

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username, :role])
    # Always set role to :user on registration
    # |> put_change(:role, :user)
    |> validate_email(opts)
    |> validate_username()
    |> validate_role()
    |> validate_password(opts)
  end

  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :username,
      :provider,
      :provider_uid,
      :provider_token,
      :provider_refresh_token,
      :provider_expires_at,
      :avatar_url,
      :confirmed_at
    ])
    |> validate_required([:email, :provider, :provider_uid])
    |> validate_email(validate_email: true)
    |> validate_username()
    |> put_change(:role, :user)
    |> unique_constraint([:provider, :provider_uid],
      name: :users_provider_uid_index,
      message: "has already been taken for this provider"
    )
  end

  def link_oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :provider,
      :provider_uid,
      :provider_token,
      :provider_refresh_token,
      :provider_expires_at,
      :avatar_url
    ])
    |> validate_required([:provider, :provider_uid])
    |> unique_constraint([:provider, :provider_uid],
      name: :users_provider_uid_index,
      message: "has already been linked to another account"
    )
  end

  def update_oauth_token_changeset(user, token, refresh_token \\ nil, expires_at \\ nil) do
    attrs = %{
      provider_token: token,
      provider_refresh_token: refresh_token,
      provider_expires_at: expires_at
    }

    user
    |> cast(attrs, [:provider_token, :provider_refresh_token, :provider_expires_at])
  end

  # ============================================================================
  # VALIDATE
  # ============================================================================

  defp validate_role(changeset) do
    changeset
    |> validate_required([:role])
    |> unique_constraint(:username)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 25)
    |> unsafe_validate_unique(:username, Narasihistorian.Repo)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password], message: "Password tidak boleh kosong")
    |> validate_length(:password, min: 12, max: 72, message: "Password minimal 10 karakter")
    |> validate_format(:password, ~r/[A-Z]/, message: "Setidaknya memakai huruf besar")
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  # ============================================================================
  # MAYBE OPTIONAL
  # ============================================================================

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Narasihistorian.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  # ============================================================================
  # UPDATE CHANGESET
  # ============================================================================

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_username()
    |> case do
      %{changes: %{username: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :username, "did not change")
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end

  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%Narasihistorian.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  # ============================================================================
  # ROLE CHECKING HELPERS
  # ============================================================================

  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false

  def user?(%__MODULE__{role: :user}), do: true
  def user?(_), do: false

  def valid_roles, do: @valid_roles

  # ============================================================================
  # OAUTH HELPERS
  # ============================================================================

  @doc """
  Checks if user is an OAuth user (has provider set).
  """

  def oauth_user?(%__MODULE__{provider: provider}) when is_binary(provider), do: true
  def oauth_user?(_), do: false

  @doc """
  Checks if user signed up with traditional email/password.
  """

  def traditional_user?(%__MODULE__{provider: nil, hashed_password: hashed_password})
      when is_binary(hashed_password),
      do: true

  def traditional_user?(_), do: false

  @doc """
  Gets the display name for OAuth provider.
  """

  def provider_display_name("google"), do: "Google"
  def provider_display_name("github"), do: "GitHub"
  def provider_display_name("facebook"), do: "Facebook"
  def provider_display_name(_), do: "OAuth"
end
