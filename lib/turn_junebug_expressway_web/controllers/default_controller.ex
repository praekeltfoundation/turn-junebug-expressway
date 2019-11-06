defmodule TurnJunebugExpresswayWeb.DefaultController do
  use TurnJunebugExpresswayWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "All good")
  end
end
