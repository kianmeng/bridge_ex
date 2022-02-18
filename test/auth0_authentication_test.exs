defmodule BridgeEx.Auth0AuthenticationTest do
  use ExUnit.Case, async: false

  import BridgeEx.TestHelper

  doctest BridgeEx.Graphql

  @fake_jwt "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im15X2tpZCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxMjMsImV4cCI6MTIzMTIzMTIzfQ.qq5yV_Lr6BHOgq5-oWk91Y6F26awQ-82Nn9__7-w9Xg"

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "authenticates via auth0 when auth0_audience is set", %{bypass: bypass} do
    set_auth0_configuration(bypass.port)
    reload_app()
    on_exit(&reload_app/0)

    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, valid_auth0_response())
    end)

    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      assert {"authorization", "Bearer #{@fake_jwt}"} in conn.req_headers
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestBridgeWithAuth0 do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        auth0: [audience: "my-audience", enabled: true]
    end

    assert {:ok, %{key: "value"}} = TestBridgeWithAuth0.call("myquery", %{})
  end

  @tag capture_log: true
  test "returns error when auth0 is enabled for bridge but not for app", %{bypass: bypass} do
    set_auth0_configuration(bypass.port, _auth0_enabled_for_app = false)
    reload_app()
    on_exit(&reload_app/0)

    defmodule TestBridgeWithAuth0EnabledOnlyInBridge do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        auth0: [audience: "my-audience", enabled: true]
    end

    assert {:error, _} = TestBridgeWithAuth0EnabledOnlyInBridge.call("myquery", %{})
  end

  defp valid_auth0_response do
    ~s<{"access_token":"#{@fake_jwt}","expires_in":86400,"token_type":"Bearer"}>
  end
end