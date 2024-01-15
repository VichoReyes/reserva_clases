defmodule ReservaClases.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ReservaClases.Repo

  alias ReservaClases.Accounts.{Administrator, AdministratorToken, AdministratorNotifier}

  ## Database getters

  @doc """
  Gets a administrator by email.

  ## Examples

      iex> get_administrator_by_email("foo@example.com")
      %Administrator{}

      iex> get_administrator_by_email("unknown@example.com")
      nil

  """
  def get_administrator_by_email(email) when is_binary(email) do
    Repo.get_by(Administrator, email: email)
  end

  @doc """
  Gets a administrator by email and password.

  ## Examples

      iex> get_administrator_by_email_and_password("foo@example.com", "correct_password")
      %Administrator{}

      iex> get_administrator_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_administrator_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    administrator = Repo.get_by(Administrator, email: email)
    if Administrator.valid_password?(administrator, password), do: administrator
  end

  @doc """
  Gets a single administrator.

  Raises `Ecto.NoResultsError` if the Administrator does not exist.

  ## Examples

      iex> get_administrator!(123)
      %Administrator{}

      iex> get_administrator!(456)
      ** (Ecto.NoResultsError)

  """
  def get_administrator!(id), do: Repo.get!(Administrator, id)

  ## Administrator registration

  @doc """
  Registers a administrator.

  ## Examples

      iex> register_administrator(%{field: value})
      {:ok, %Administrator{}}

      iex> register_administrator(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_administrator(attrs) do
    %Administrator{}
    |> Administrator.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking administrator changes.

  ## Examples

      iex> change_administrator_registration(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_registration(%Administrator{} = administrator, attrs \\ %{}) do
    Administrator.registration_changeset(administrator, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the administrator email.

  ## Examples

      iex> change_administrator_email(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_email(administrator, attrs \\ %{}) do
    Administrator.email_changeset(administrator, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_administrator_email(administrator, "valid password", %{email: ...})
      {:ok, %Administrator{}}

      iex> apply_administrator_email(administrator, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_administrator_email(administrator, password, attrs) do
    administrator
    |> Administrator.email_changeset(attrs)
    |> Administrator.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the administrator email using the given token.

  If the token matches, the administrator email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_administrator_email(administrator, token) do
    context = "change:#{administrator.email}"

    with {:ok, query} <- AdministratorToken.verify_change_email_token_query(token, context),
         %AdministratorToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(administrator_email_multi(administrator, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp administrator_email_multi(administrator, email, context) do
    changeset =
      administrator
      |> Administrator.email_changeset(%{email: email})
      |> Administrator.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdministratorToken.by_administrator_and_contexts_query(administrator, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given administrator.

  ## Examples

      iex> deliver_administrator_update_email_instructions(administrator, current_email, &url(~p"/administrators/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_administrator_update_email_instructions(%Administrator{} = administrator, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, administrator_token} = AdministratorToken.build_email_token(administrator, "change:#{current_email}")

    Repo.insert!(administrator_token)
    AdministratorNotifier.deliver_update_email_instructions(administrator, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the administrator password.

  ## Examples

      iex> change_administrator_password(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_password(administrator, attrs \\ %{}) do
    Administrator.password_changeset(administrator, attrs, hash_password: false)
  end

  @doc """
  Updates the administrator password.

  ## Examples

      iex> update_administrator_password(administrator, "valid password", %{password: ...})
      {:ok, %Administrator{}}

      iex> update_administrator_password(administrator, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_administrator_password(administrator, password, attrs) do
    changeset =
      administrator
      |> Administrator.password_changeset(attrs)
      |> Administrator.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdministratorToken.by_administrator_and_contexts_query(administrator, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{administrator: administrator}} -> {:ok, administrator}
      {:error, :administrator, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_administrator_session_token(administrator) do
    {token, administrator_token} = AdministratorToken.build_session_token(administrator)
    Repo.insert!(administrator_token)
    token
  end

  @doc """
  Gets the administrator with the given signed token.
  """
  def get_administrator_by_session_token(token) do
    {:ok, query} = AdministratorToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_administrator_session_token(token) do
    Repo.delete_all(AdministratorToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given administrator.

  ## Examples

      iex> deliver_administrator_confirmation_instructions(administrator, &url(~p"/administrators/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_administrator_confirmation_instructions(confirmed_administrator, &url(~p"/administrators/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_administrator_confirmation_instructions(%Administrator{} = administrator, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if administrator.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, administrator_token} = AdministratorToken.build_email_token(administrator, "confirm")
      Repo.insert!(administrator_token)
      AdministratorNotifier.deliver_confirmation_instructions(administrator, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a administrator by the given token.

  If the token matches, the administrator account is marked as confirmed
  and the token is deleted.
  """
  def confirm_administrator(token) do
    with {:ok, query} <- AdministratorToken.verify_email_token_query(token, "confirm"),
         %Administrator{} = administrator <- Repo.one(query),
         {:ok, %{administrator: administrator}} <- Repo.transaction(confirm_administrator_multi(administrator)) do
      {:ok, administrator}
    else
      _ -> :error
    end
  end

  defp confirm_administrator_multi(administrator) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, Administrator.confirm_changeset(administrator))
    |> Ecto.Multi.delete_all(:tokens, AdministratorToken.by_administrator_and_contexts_query(administrator, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given administrator.

  ## Examples

      iex> deliver_administrator_reset_password_instructions(administrator, &url(~p"/administrators/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_administrator_reset_password_instructions(%Administrator{} = administrator, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, administrator_token} = AdministratorToken.build_email_token(administrator, "reset_password")
    Repo.insert!(administrator_token)
    AdministratorNotifier.deliver_reset_password_instructions(administrator, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the administrator by reset password token.

  ## Examples

      iex> get_administrator_by_reset_password_token("validtoken")
      %Administrator{}

      iex> get_administrator_by_reset_password_token("invalidtoken")
      nil

  """
  def get_administrator_by_reset_password_token(token) do
    with {:ok, query} <- AdministratorToken.verify_email_token_query(token, "reset_password"),
         %Administrator{} = administrator <- Repo.one(query) do
      administrator
    else
      _ -> nil
    end
  end

  @doc """
  Resets the administrator password.

  ## Examples

      iex> reset_administrator_password(administrator, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Administrator{}}

      iex> reset_administrator_password(administrator, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_administrator_password(administrator, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, Administrator.password_changeset(administrator, attrs))
    |> Ecto.Multi.delete_all(:tokens, AdministratorToken.by_administrator_and_contexts_query(administrator, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{administrator: administrator}} -> {:ok, administrator}
      {:error, :administrator, changeset, _} -> {:error, changeset}
    end
  end
end
