defmodule SignedRequest.SignedURITest do
  use ExUnit.Case
  doctest SignedRequest.SignedURI

  alias SignedRequest.{SignedURI}

  setup do
    Application.put_env(:signed_request, :secret_key, "foo")
    {:ok, %{}}
  end

  def hmac(string) do
    secret = Application.get_env(:signed_request, :secret_key)
    :crypto.mac(:hmac, :sha256, secret, string)
    |> Base.encode16
    |> String.downcase
  end

  describe "encode" do
    test "returns encoded query string adding sig" do
      query = %{
        foo: 1,
        bar: 2
      }

      signature = hmac("bar=2&foo=1")
      expected_query_string = "sig=#{signature}&bar=2&foo=1"

      assert SignedURI.encode_query(query) == expected_query_string
    end
  end

  describe "decode" do
    test "returns decoded query" do
      signature = hmac("bar=2&foo=1")
      query_string = "sig=#{signature}&bar=2&foo=1"

      expected_query = %{
        "foo" => "1",
        "bar" => "2",
        "sig" => signature,
      }

      assert {:ok, query} = SignedURI.decode_query(query_string)
      assert query == expected_query
    end

    test "returns error if signed_request is invalid" do
      query_string = "sig=random-value&bar=2&foo=1"
      assert {:error, :invalid_hmac} = SignedURI.decode_query(query_string)
    end
  end
end
