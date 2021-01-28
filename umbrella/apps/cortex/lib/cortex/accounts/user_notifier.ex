defmodule Cortex.Accounts.UserNotifier do
  import Swoosh.Email
  alias Cortex.Mailer
  require Logger

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, body) do
    subject = "TEST TEST"
    case new()
         |> to(to)
         |> from({"Expanded Stats", "stats@futureperfect.studio"})
         |> subject(subject)
         # |> html_body("<h1>Hello #{user.name}</h1>")
         |> text_body(body)
         |> Mailer.deliver() do

      {:ok, %{}} ->
        # Testing only
        {:ok, %{to: to, body: body}}

      # See source at `deps/swoosh/lib/swoosh/adapters/mailgun.ex`
      #
      {:ok, %{id: id}} ->
        Logger.debug(
          "#{__MODULE__} Delivered email to #{to}, Mailgun ID: #{id}"
        )

        # NOTE  This is unused when run by the Rihanna queue processor, but
        #       might as well keep the sig similar to `deliver_now` so they can
        #       be swapped readily... see notes there.
        {:ok, %{to: to, body: body, id: id}}

      {:error, error} ->
        # NOTE  I can't find **any** documentation of error responses on
        #       the Mailgun site:
        #
        #       https://documentation.mailgun.com/en/latest/api_reference.html
        #
        #       I want to say I expected better, but... sigh.
        #
        Logger.error(
          "#{__MODULE__} FAILED to deliver to #{to}: #{inspect(error)}"
        )

        # NOTE  Can return `{:reenqueue, due_at}` to, well... you get it.
        #
        #       https://github.com/samsondav/rihanna/blob/f0c2709f93d9fb1b68100e1722b31f8674c0a9f5/lib/rihanna/job_dispatcher.ex#L66
        #
        # This ends up in the `fail_reason` col in the job's db row.
        {:error, error}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
