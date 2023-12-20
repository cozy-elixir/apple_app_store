defmodule AppleAppStore.Receipts do
  @moduledoc """
  App Store Receipts - validates app and in-app purchase receipts with the
  App Store.

  > App Store Receipts has been deprecated by Apple.

  Read more at <https://developer.apple.com/documentation/appstorereceipts>.
  """

  alias __MODULE__.HTTPClient

  @typedoc """
  The Base64-encoded receipt data.
  """
  @type receipt_data :: String.t()

  @typedoc """
  The app's shared secret.
  """
  @type app_shared_secret :: String.t()

  @type option :: {:exclude_old_transactions, boolean()}
  @type options :: [option()]

  @doc """
  Sends a receipt to the App Store for verification.

  The receipt will be sent to production environment first. If a 21007 status
  code is returned, then receipt will be sent to sandbox environment.
  Following this approach ensures that we do not have to switch between URLs
  while your application is tested, reviewed by App Review, or live in the App
  Store.

  Read more at [Validating receipts with the App Store](https://developer.apple.com/documentation/appstorereceipts/validating_receipts_with_the_app_store).
  """
  @spec verify_receipt(receipt_data(), app_shared_secret(), options()) ::
          {:ok, map()} | {:error, Tesla.Env.t()} | {:error, any()}
  def verify_receipt(receipt_data, app_shared_secret, options \\ []) do
    case verify_receipt_in_production(receipt_data, app_shared_secret, options) do
      {:error, :retry} ->
        verify_receipt_in_sandbox(receipt_data, app_shared_secret, options)

      other ->
        other
    end
  end

  defp verify_receipt_in_production(receipt_data, app_shared_secret, options) do
    request(HTTPClient.Production, receipt_data, app_shared_secret, options)
  end

  defp verify_receipt_in_sandbox(receipt_data, app_shared_secret, options) do
    request(HTTPClient.Sandbox, receipt_data, app_shared_secret, options)
  end

  defp request(http_client, receipt_data, app_shared_secret, options) do
    http_client.post("/verifyReceipt", %{
      "receipt-data" => receipt_data,
      "password" => app_shared_secret,
      "exclude-old-transactions" => Keyword.get(options, :exclude_old_transactions, false)
    })
    |> case do
      {:ok, %Tesla.Env{status: 200, body: %{"status" => 0} = body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: %{"status" => 21_007}}} ->
        {:error, :retry}

      {:ok, env} ->
        {:error, env}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
