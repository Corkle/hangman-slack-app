defmodule HangmanWeb.OauthControllerTest do
  use HangmanWeb.ConnCase

  defp get_endpoint(params),
    do: get(build_conn(), "/oauth/authorized", params)

  describe "GET /oauth/authorized" do
    test "url params contain error, should send authorization failed error response" do
      res = get_endpoint(%{"error" => "access_denied"})
      assert res.status == 400 
      assert res.resp_body == "Hangman needs your permission to integrate with your Slack team. Please use the Add to Slack button to grant the requested authorization."
    end

    test "url params include invalid slack access code, should send response for invalid Slack authorization." do
      params = %{"code" => "INVALID_CODE", "state" => ""}
      res = get_endpoint(params)
      assert res.status == 400 
      assert res.resp_body == "Slack did not recognize the access code generated from your authorization approval. Please use the Add to Slack button to grant authorization again."
    end

    test "url params include a valid slack access code, should save token and send success response" do
      params = %{"code" => "VALID_CODE", "state" => ""}
      res = get_endpoint(params)
      assert res.status == 200
      assert res.resp_body == "Success! Hangman has been added to your Slack team. Try out the /playhangman command from the channels you have authroized. You may now close this page."
    end

    test "url does not include expected params, should send invalid request response." do
      res = get_endpoint(%{})
      assert res.status == 400
      assert res.resp_body == "bad request"
    end
  end
end

