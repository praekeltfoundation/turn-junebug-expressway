defmodule TurnJunebugExpresswayWeb.DefaultController do
  use TurnJunebugExpresswayWeb, :controller
  use Tesla

  alias TurnJunebugExpresswayWeb.Utils

  def index(conn, _params) do
    case Utils.get_env(:rabbitmq, :management_interface) do
      nil ->
        send_resp(conn, 200, "All good")

      management_interface ->
        {stuck, queue_details} = Utils.get_all_queue_details(management_interface)

        {status_code, description} =
          case stuck do
            true -> {500, "queues stuck"}
            false -> {200, "queues ok"}
          end

        send_resp(
          conn,
          status_code,
          Jason.encode!(%{"description" => description, "result" => queue_details})
        )
    end
  end
end
