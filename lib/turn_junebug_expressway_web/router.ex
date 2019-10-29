defmodule TurnJunebugExpresswayWeb.Router do
  use TurnJunebugExpresswayWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api/v1", TurnJunebugExpresswayWeb do
    pipe_through(:api)

    resources("/send_message", MessageController, only: [:create])
  end
end
