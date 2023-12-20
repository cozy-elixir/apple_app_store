defmodule AppleAppStore.Receipts.HTTPClient.Sandbox do
  @moduledoc false

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://sandbox.itunes.apple.com/"
  plug Tesla.Middleware.JSON
end
