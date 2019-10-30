defmodule TurnJunebugExpresswayWeb.MessageController do
  use TurnJunebugExpresswayWeb, :controller

  alias TurnJunebugExpresswayWeb.Utils

  def create(conn, _params) do
    case conn |> Utils.validate_hmac_signature() do
      {:ok, _} ->
        # TODO: validation
        # TODO: error handling
        {:ok, message} = Utils.format_message(conn)

        Utils.send_message(message)

        conn
        |> put_status(202)
        |> json(%{
          messages: [
            %{
              id: get_in(message, ["message_id"])
            }
          ]
        })

      {:error, message} ->
        {403, message}

        conn
        |> send_resp(403, message)
        |> halt()
    end
  end
end
