defmodule TurnJunebugExpresswayWeb.Router do
  use TurnJunebugExpresswayWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api/v1", TurnJunebugExpresswayWeb do
    pipe_through(:api)

    resources("/send_message", MessageController, only: [:create])
  end

  scope "/", TurnJunebugExpresswayWeb do
    resources("/health", DefaultController, only: [:index])
  end
end
