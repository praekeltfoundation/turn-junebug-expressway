defmodule TurnJunebugExpressway.HttpPushEngineTest do
  use ExUnit.Case
  alias TurnJunebugExpressway.HttpPushEngine

  describe "start_link/1" do
    test "restarts another process when something goes wrong" do
      started_pid = Process.whereis(HttpPushEngine)

      send(started_pid, {:EXIT, started_pid, :client_down})

      :timer.sleep(100)

      new_pid = Process.whereis(HttpPushEngine)

      assert started_pid != new_pid
    end
  end
end
