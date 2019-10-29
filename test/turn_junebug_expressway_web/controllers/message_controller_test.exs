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
      conn =
        build_conn()
        |> put_req_header(
          "http_x_engage_hook_signature",
          "dgbfxbVUkQW91ViBGxxeUefGksPEWr3Fu9RHB7ciXns="
        )
        |> post("/api/v1/send_message", test: "test")

      assert conn.status == 200
      assert conn.resp_body =~ "success"
    end
  end
end
