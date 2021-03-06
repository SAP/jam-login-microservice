defmodule LoginProxy.ForwarderTest do
  use LoginProxy.ConnCase
  alias LoginProxy.HttpMock

  setup %{conn: conn} do
    {:ok, _} = HttpMock.start()

    {:ok, conn: conn}
  end

  test "GET /ui/job/ConversationServiceBuild/", %{conn: conn} do
    HttpMock.set_response(%{
      status_code: 200,
      body: "<html><body>ConversationServiceBuild</body></html>",
      headers: %{hdrs: [{"content-type", "text/html"}]}
    })

    conn = LoginProxy.LoginMock.login(conn)
    conn = get conn, "/ui/job/ConversationServiceBuild/"
    assert html_response(conn, 200) =~ "ConversationServiceBuild"
    refute Plug.Conn.get_resp_header(conn, "not-authenticated") |> Enum.at(0)
    # Validate that a GET request to the url was made internally
    request = HttpMock.get_request()
    #assert %{method: :get, url: "#{url}/ui/job/ConversationServiceBuild/"} = request     # elixir can't handle this
    assert :get == request.method
    assert "#{Application.get_env(:login_proxy, :browser_server_url)}/ui/job/ConversationServiceBuild/" == request.url
    assert request.headers[:authentication] =~ "Bearer "
    token = request.headers[:authentication] |> String.split() |> Enum.at(1)
    assert {:ok, user} = LoginProxy.Jwt.verify_token(token, Application.get_env(:login_proxy, :jwt_hs256_secret))
    assert %{"email" => _, "firstname" => _, "lastname" => _} = user
    assert "50c5a290-146d-4d54-944c-1bfad270718d" == request.headers[:tenant_uuid]
  end

  test "GET /ui/job/ConversationServiceBuild/ (auth failure)", %{conn: conn} do
    get conn, "/auth/logout"
    conn = Plug.Conn.put_req_header(conn, "accept", "text/html")
    conn = get conn, "/ui/job/ConversationServiceBuild/"
    assert html_response(conn, 302) =~ ~r/You are being.*redirected/
    refute Plug.Conn.get_resp_header(conn, "not-authenticated") |> Enum.at(0)
  end

  test "AJAX GET /testing/api (auth failure)", %{conn: conn} do
    get conn, "/auth/logout"
    conn = Plug.Conn.put_req_header(conn, "x-requested-with", "XMLHttpRequest")
    |> Plug.Conn.put_req_header("accept", "application/json")
    conn = get conn, "/testing/api"
    assert json_response(conn, 401) ==  %{"error" => %{"message" => "Unauthorized", "code" => 401}}
    assert Plug.Conn.get_resp_header(conn, "not-authenticated") |> Enum.at(0)
  end

  test "Asset GET /ui/image.png (auth failure)", %{conn: conn} do
    get conn, "/auth/logout"
    conn = Plug.Conn.put_req_header(conn, "accept", "*/*")
    conn = get conn, "/ui/image.png"
    assert json_response(conn, 401) ==  %{"error" => %{"message" => "Unauthorized", "code" => 401}}
    assert Plug.Conn.get_resp_header(conn, "not-authenticated") |> Enum.at(0)
  end

  test "GET api /testing/api", %{conn: conn} do
    HttpMock.set_response(%{
      status_code: 200,
      body: ~s({"results": [1,2,3]}),
      headers: %{hdrs: [{"content-type", "application/json"}, {"x-requested-with", "XMLHttpRequest"}]}
    })

    conn = LoginProxy.LoginMock.login(conn)
    conn = get conn, "/testing/api"
    assert json_response(conn, 200) == %{"results" => [1,2,3]}
    # Validate that a GET request to the url was made internally
    request = HttpMock.get_request()
    #assert %{method: :get, url: "#{url}/testing/api"} = request     # elixir can't handle this
    assert :get == request.method
    assert "#{Application.get_env(:login_proxy, :api_server_url)}/testing/api" == request.url
    assert request.headers[:authentication] =~ "Bearer "
    token = request.headers[:authentication] |> String.split() |> Enum.at(1)
    assert {:ok, user} = LoginProxy.Jwt.verify_token(token, Application.get_env(:login_proxy, :jwt_hs256_secret))
    assert %{"email" => _, "firstname" => _, "lastname" => _} = user
    assert "50c5a290-146d-4d54-944c-1bfad270718d" == request.headers[:tenant_uuid]
  end

end
