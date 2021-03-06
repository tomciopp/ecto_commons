defmodule EctoCommons.EmailValidator do
  @moduledoc ~S"""
  Validates emails.

  ## Options
  There are various `:checks` depending on the strictness of the validation you require. Indeed, perfect email validation
  does not exist (see StackOverflow questions about it):

  - `:html_input`: Checks if the email follows the regular expression used by browsers for
    their `type="email"` input fields. This is the default as it corresponds to most use-cases. It is quite strict
    without being too narrow. It does not support unicode emails though. If you need better internationalization,
    please use the `:pow` check as it is more flexible with international emails. Defaults to enabled.
  - `:burner`: Checks if the email given is a burner email provider. When enabled, will reject temporary
    email providers. Defaults to disabled.
  - `:pow`: Checks the email using the [`pow`](https://hex.pm/packages/pow) logic. Defaults to disabled.
    The rules are the following:
    - Split into local-part and domain at last `@` occurrence
    - Local-part should;
      - be at most 64 octets
      - separate quoted and unquoted content with a single dot
      - only have letters, digits, and the following characters outside quoted
        content:
          ```text
          !#$%&'*+-/=?^_`{|}~.
          ```
      - not have any consecutive dots outside quoted content
    - Domain should;
      - be at most 255 octets
      - only have letters, digits, hyphen, and dots
      - do not start or end with hyphen or dot
      - can be an IPv4 or IPv6 address
    Unicode characters are permitted in both local-part and domain.

  ## Example:

      iex> types = %{email: :string}
      iex> params = %{email: "valid.email@example.com"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email)
      #Ecto.Changeset<action: nil, changes: %{email: "valid.email@example.com"}, errors: [], data: %{}, valid?: true>

      iex> types = %{email: :string}
      iex> params = %{email: "@invalid_email"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email)
      #Ecto.Changeset<action: nil, changes: %{email: "@invalid_email"}, errors: [email: {"is not a valid email", [validation: :email]}], data: %{}, valid?: false>

      iex> types = %{email: :string}
      iex> params = %{email: "uses_a_forbidden_provider@yopmail.net"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email, checks: [:html_input, :burner])
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [email: {"uses a forbidden provider", [validation: :email]}], data: %{}, valid?: false>

      iex> types = %{email: :string}
      iex> params = %{email: "uses_a_forbidden_provider@yopmail.net"}
      iex> Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      ...> |> validate_email(:email, checks: [:html_input, :pow])
      #Ecto.Changeset<action: nil, changes: %{email: "uses_a_forbidden_provider@yopmail.net"}, errors: [], data: %{}, valid?: true>

  """

  import Ecto.Changeset

  # We use the regular expression of the html `email` field specification.
  # See https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)
  # and https://stackoverflow.com/a/15659649/1656568
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @ipv6_regex ~r/(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))/
  @ipv4_regex ~r/((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])/

  def validate_email(%Ecto.Changeset{} = changeset, field, opts \\ []) do
    validate_change(changeset, field, {:email, opts}, fn _, value ->
      checks = Keyword.get(opts, :checks, [:pow])

      # credo:disable-for-lines:6 Credo.Check.Refactor.Nesting
      Enum.reduce(checks, [], fn check, errors ->
        case do_validate_email(value, check) do
          :ok -> errors
          {:error, msg} -> [{field, {message(opts, msg), [validation: :email]}} | errors]
        end
      end)
      |> List.flatten()
    end)
  end

  @spec do_validate_email(String.t(), atom()) :: :ok | {:error, String.t()}
  defp do_validate_email(email, :burner) do
    case Burnex.is_burner?(email) do
      true ->
        {:error, "uses a forbidden provider"}

      false ->
        :ok
    end
  end

  defp do_validate_email(email, :html_input) do
    if String.match?(email, @email_regex),
      do: :ok,
      else: {:error, "is not a valid email"}
  end

  defp do_validate_email(email, :pow) do
    case pow_validate_email(email) do
      :ok -> :ok
      {:error, _msg} -> {:error, "is not a valid email"}
    end
  end

  # The code below is copied and adapted from the [pow](https://hex.pm/packages/pow) package
  # with a few fixes on the domain part.
  defp pow_validate_email(email) do
    [domain | rest] =
      email
      |> String.split("@")
      |> Enum.reverse()

    local_part =
      rest
      |> Enum.reverse()
      |> Enum.join("@")

    cond do
      String.length(local_part) > 64 -> {:error, "local-part too long"}
      String.length(domain) > 255 -> {:error, "domain too long"}
      local_part == "" -> {:error, "invalid format"}
      true -> pow_validate_email(local_part, domain)
    end
  end

  defp pow_validate_email(local_part, domain) do
    sanitized_local_part = remove_quotes_from_local_part(local_part)

    cond do
      local_part_only_quoted?(local_part) ->
        validate_domain(domain)

      local_part_consecutive_dots?(sanitized_local_part) ->
        {:error, "consecutive dots in local-part"}

      local_part_valid_characters?(sanitized_local_part) ->
        validate_domain(domain)

      true ->
        {:error, "invalid characters in local-part"}
    end
  end

  defp remove_quotes_from_local_part(local_part),
    do: Regex.replace(~r/(^\".*\"$)|(^\".*\"\.)|(\.\".*\"$)?/, local_part, "")

  defp local_part_only_quoted?(local_part), do: local_part =~ ~r/^"[^\"]+"$/

  defp local_part_consecutive_dots?(local_part), do: local_part =~ ~r/\.\./

  defp local_part_valid_characters?(sanitized_local_part),
    do: sanitized_local_part =~ ~r<^[\p{L}0-9!#$%&'*+-/=?^_`{|}~\.]+$>u

  defp validate_domain(domain) do
    cond do
      String.first(domain) == "-" -> {:error, "domain begins with hyphen"}
      String.first(domain) == "." -> {:error, "domain begins with a dot"}
      String.last(domain) == "-" -> {:error, "domain ends with hyphen"}
      String.last(domain) == "." -> {:error, "domain ends with a dot"}
      domain =~ ~r/^[\p{L}0-9-\.]+$/u -> :ok
      domain =~ @ipv6_regex -> :ok
      domain =~ @ipv4_regex -> :ok
      true -> {:error, "invalid domain"}
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
