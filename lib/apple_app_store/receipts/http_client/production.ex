defmodule AppleAppStore.Receipts.HTTPClient.Production do
  @moduledoc false

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://buy.itunes.apple.com"
  plug Tesla.Middleware.JSON
end
