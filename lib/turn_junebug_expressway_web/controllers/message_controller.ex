defmodule TurnJunebugExpresswayWeb.MessageController do
  use TurnJunebugExpresswayWeb, :controller

  alias TurnJunebugExpresswayWeb.Utils

  def create(conn, _params) do
    case conn |> Utils.validate_hmac_signature() do
      {:ok, _} ->
        text(conn, "success")

      {:error, message} ->
        conn
        |> send_resp(403, message)
        |> halt()
    end
  end
end
