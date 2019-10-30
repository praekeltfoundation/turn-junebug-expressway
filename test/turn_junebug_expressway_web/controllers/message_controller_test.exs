defmodule TurnJunebugExpresswayWeb.MessageControllerTest do
  use TurnJunebugExpresswayWeb.ConnCase

  describe "validate hmac signature in header" do
    test "error when hmac header is invalid", %{} do
      conn =
        build_conn()
        |> put_req_header("http_x_engage_hook_signature", "bla bla bla")
        |> post("/api/v1/send_message", test: "test")

      assert conn.status == 403
      assert conn.resp_body =~ "invalid hmac signature"
    end

    test "missing?", %{} do
      conn =
        build_conn()
        |> post("/api/v1/send_message", test: "test")

      assert conn.status == 403
      assert conn.resp_body =~ "missing hmac signature"
    end

    test "success when hmac header is valid", %{} do
      {:ok, data} =
        Jason.encode(%{
          "preview_url" => false,
          "recipient_type" => "individual",
          "text" => %{"body" => "text message content"},
          "to" => "whatsapp_id",
          "type" => "text"
        })

      conn =
        build_conn()
        |> put_req_header(
          "http_x_engage_hook_signature",
          "jW/nhuaGDB2IMv2nBlzEngmBGiHX4cZeTsSHuiESTmc="
        )
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/send_message", data)

      assert conn.status == 202
      {:ok, response_body} = Jason.decode(conn.resp_body)
      assert response_body == %{"messages" => [%{"id" => "long_random_message_id"}]}
    end
  end
end
