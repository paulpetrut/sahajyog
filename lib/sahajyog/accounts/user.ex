defmodule Sahajyog.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :role, :string, default: "user"
    field :level, :string, default: "Level1"
    alias Sahajyog.Events.{EventAttendance, EventRideRequest}

    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string
    field :city, :string
    field :country, :string

    has_many :attendances, EventAttendance
    has_many :ride_requests, EventRideRequest, foreign_key: :passenger_user_id

    timestamps(type: :utc_datetime)
  end

  @roles ~w(admin user)
  @levels ~w(Level1 Level2 Level3)

  def roles, do: @roles
  def levels, do: @levels

  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_), do: false

  def user?(%__MODULE__{role: "user"}), do: true
  def user?(_), do: false

  @doc """
  Checks if a user can access events.
  Events are accessible to users with level L1, L2, L3, or admin role.
  """
  def can_access_events?(%__MODULE__{role: "admin"}), do: true
  def can_access_events?(%__MODULE__{level: level}) when level in @levels, do: true
  def can_access_events?(_), do: false

  @doc """
  Checks if a user is eligible to see the upgrade option.
  Requirement: Level1 user AND registered more than 30 days ago.
  """
  def eligible_for_upgrade?(%__MODULE__{level: "Level1", inserted_at: inserted_at}) do
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30, :day)
    DateTime.compare(inserted_at, thirty_days_ago) == :lt
  end

  def eligible_for_upgrade?(_), do: false

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, Sahajyog.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

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

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Sahajyog.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  A user changeset for changing the profile.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :phone_number, :city, :country])
    |> validate_length(:first_name, max: 50)
    |> validate_length(:last_name, max: 50)
    |> validate_length(:phone_number, max: 20)
    |> validate_length(:city, max: 100)
    |> validate_length(:country, max: 100)
  end

  def country_codes do
    [
      {"United States", "+1"},
      {"United Kingdom", "+44"},
      {"Canada", "+1"},
      {"Australia", "+61"},
      {"India", "+91"},
      {"Germany", "+49"},
      {"France", "+33"},
      {"Italy", "+39"},
      {"Spain", "+34"},
      {"Brazil", "+55"},
      {"Mexico", "+52"},
      {"Japan", "+81"},
      {"China", "+86"},
      {"Russia", "+7"},
      {"South Africa", "+27"},
      {"Romania", "+40"},
      {"Poland", "+48"},
      {"Netherlands", "+31"},
      {"Turkey", "+90"},
      {"Austria", "+43"},
      {"Switzerland", "+41"},
      {"Belgium", "+32"},
      {"Sweden", "+46"},
      {"Norway", "+47"},
      {"Denmark", "+45"},
      {"Finland", "+358"},
      {"Ireland", "+353"},
      {"Portugal", "+351"},
      {"Greece", "+30"},
      {"New Zealand", "+64"},
      {"Singapore", "+65"},
      {"Malaysia", "+60"},
      {"Thailand", "+66"},
      {"Indonesia", "+62"},
      {"Vietnam", "+84"},
      {"Philippines", "+63"},
      {"Argentina", "+54"},
      {"Chile", "+56"},
      {"Colombia", "+57"},
      {"Peru", "+51"},
      {"Venezuela", "+58"},
      {"Egypt", "+20"},
      {"Nigeria", "+234"},
      {"Kenya", "+254"},
      {"Israel", "+972"},
      {"Saudi Arabia", "+966"},
      {"United Arab Emirates", "+971"},
      {"Ukraine", "+380"},
      {"Czech Republic", "+420"},
      {"Hungary", "+36"}
    ]
  end

  def profile_complete?(user) do
    !is_nil(user.first_name) && user.first_name != "" &&
      !is_nil(user.last_name) && user.last_name != "" &&
      !is_nil(user.phone_number) && user.phone_number != ""
  end
end
