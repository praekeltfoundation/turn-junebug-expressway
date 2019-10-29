defmodule TurnJunebugExpresswayWeb.Utils do
  def validate_hmac_signature(conn) do
    header_hmac =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("http_x_engage_hook_signature")

    our_hmac =
      :crypto.hmac(
        :sha256,
        Application.get_env(:turn_junebug_expressway, :turn)[:hmac_secret],
        conn.private[:raw_body]
      )
      |> Base.encode64()

    case {header_hmac, our_hmac == header_hmac} do
      {nil, _} -> {:error, "missing hmac signature"}
      {_, false} -> {:error, "invalid hmac signature"}
      {_, true} -> {:ok, "good hmac"}
    end
  end
end
