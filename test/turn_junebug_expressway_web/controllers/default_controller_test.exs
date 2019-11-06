defmodule TurnJunebugExpresswayWeb.DefaultControllerTest do
  use TurnJunebugExpresswayWeb.ConnCase

  describe "health endpoint" do
    test "get should return 200", %{} do
      conn =
        build_conn()
        |> get("/health")

      assert conn.status == 200
      assert conn.resp_body =~ "All good"
    end
  end
end
