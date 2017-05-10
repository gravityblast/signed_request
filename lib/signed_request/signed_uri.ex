defmodule SignedRequest.SignedURI do
  @hmac_param_name "sig"

  @doc """
  Encode query using `URI.encode_query` and adding the signed request to a parameter called `sig`.

  ## Example
  iex> SignedRequest.SignedURI.encode_query(%{size: 512})
  "sig=7dc5fc28fa59ff89dff64bed05920978471f10ced63aca98452b54574a3aef0e&size=512"
  """
  def encode_query(params) when is_map(params) do
    params
    |> Enum.into([])
    |> encode_query
  end
  def encode_query(params) when is_list(params) do
    params
    |> Enum.sort
    |> create_hmac
    |> append_hmac(params)
    |> URI.encode_query
  end

  @doc """
  Encode query using `URI.encode_query` and adding the signed request to a parameter called `sig`.

  ## Example
  iex> SignedRequest.SignedURI.decode_query("sig=7dc5fc28fa59ff89dff64bed05920978471f10ced63aca98452b54574a3aef0e&size=512")
  {:ok, %{
    "sig" => "7dc5fc28fa59ff89dff64bed05920978471f10ced63aca98452b54574a3aef0e",
    "size" => "512"}
  }

  iex> SignedRequest.SignedURI.decode_query("sig=invalid&size=512")
  {:error, :invalid_hmac}
  """
  def decode_query(query_string) when is_binary(query_string) do
    query_string
    |> URI.decode_query
    |> decode_query
  end
  def decode_query(%{@hmac_param_name => hmac} = query) when is_map(query) do
    query
    |> Map.delete(@hmac_param_name)
    |> Enum.into([])
    |> create_hmac
    |> case do
      ^hmac ->
        {:ok, query}
      _ ->
        {:error, :invalid_hmac}
    end
  end
  def decode_query(query) when is_map(query) do
    query
    |> Map.put(@hmac_param_name, nil)
    |> decode_query
  end

  defp create_hmac(params) when is_list(params) do
    params
    |> URI.encode_query
    |> create_hmac
  end
  defp create_hmac(params) when is_binary(params) do
    :sha256
    |> :crypto.hmac(secret_key(), params)
    |> Base.encode16
    |> String.downcase
  end

  defp secret_key, do: Application.get_env(:signed_request, :secret_key)

  defp append_hmac(hmac, list), do: [{@hmac_param_name, hmac} | list]
end
