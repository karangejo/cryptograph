defmodule CryptographWeb.OHLCChartLive do
  use CryptographWeb, :live_view
  alias CoinGeckoApi


  @impl true
  def mount(%{"crypto_id" => id, "price_currency" => currency}, _session, socket) do
    {:ok, socket
              |> assign(:crypto_id, id)
              |> assign(:currency, currency)
              |> assign(:update_interval, 5000)
              |> push_event("ohlc-data", %{ohlc_data: get_ohlc_data(id, currency)})}
  end


  defp get_ohlc_data(id, currency) do
    data = CoinGeckoApi.coins_id_ohlc(id, %{"vs_currency" => currency, "days" => "365"})
    Enum.map(data, fn [t, o, h, l, c] -> [t, [o, h, l, c]] end)
  end

end
