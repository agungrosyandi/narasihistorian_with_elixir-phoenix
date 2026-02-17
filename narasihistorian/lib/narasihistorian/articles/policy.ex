defmodule Narasihistorian.Articles.Policy do
  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Articles.Article

  @doc """
  Can user view all articles (regardless of owner)?
  """

  def can_list_all?(%User{role: :admin}), do: true
  def can_list_all?(_user), do: false

  @doc """
  Can user create articles?
  """

  def can_create?(%User{}), do: true
  def can_create?(_), do: false

  @doc """
  Can user view this specific article?
  Public articles can be viewed by anyone, but this is for management/editing context.
  """

  def can_view?(%User{role: :admin}, %Article{}), do: true

  def can_view?(%User{id: user_id}, %Article{user_id: article_user_id})
      when user_id == article_user_id,
      do: true

  def can_view?(_user, _article), do: false

  @doc """
  Can user edit this article?
  """

  def can_edit?(%User{role: :admin}, %Article{}), do: true

  def can_edit?(%User{id: user_id}, %Article{user_id: article_user_id})
      when user_id == article_user_id,
      do: true

  def can_edit?(_user, _article), do: false

  @doc """
  Can user delete this article?
  """

  def can_delete?(%User{role: :admin}, %Article{}), do: true

  def can_delete?(%User{id: user_id}, %Article{user_id: article_user_id})
      when user_id == article_user_id,
      do: true

  def can_delete?(_user, _article), do: false
end
