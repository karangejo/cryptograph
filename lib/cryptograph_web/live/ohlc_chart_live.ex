defmodule CryptographWeb.OHLCChartLive do
  use CryptographWeb, :live_view
  alias CoinGeckoApi


  @impl true
  def mount(%{"crypto_id" => id, "price_currency" => currency}, _session, socket) do
    {:ok, socket
              |> assign(:crypto_id, id)
              |> assign(:currency, currency)
              |> assign(:coins_list, get_crypto_ids())
              |> assign(:currency_list, get_currency_list())
              |> push_event("ohlc-data", %{ohlc_data: get_ohlc_data(id, currency)})
              |> push_event("chart-label", %{chart_label: "Historical " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})}
  end

  @impl true
  def handle_params(%{"crypto_id" => id, "price_currency" => currency}, _uri, socket) do
    {:noreply, socket
                |> assign(:crypto_id, id)
                |> assign(:currency, currency)
                |> push_event("ohlc-data", %{ohlc_data: get_ohlc_data(id, currency)})
                |> push_event("chart-label", %{chart_label: "Historical " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})}
  end

  @impl true
  def handle_event("ohlc-chart", %{"live-chart-select" => selected_id, "live-chart-select-currency" => currency},socket) do
    {:noreply, push_patch(socket, to: Routes.ohlc_chart_path(socket, :index, selected_id, currency))}
  end


  defp get_ohlc_data(id, currency) do
    CoinGeckoApi.coins_id_ohlc(id, %{"vs_currency" => currency, "days" => "365"})
    |> Enum.map(fn [t, o, h, l, c] -> [t, [o, h, l, c]] end)
  end

  defp get_crypto_ids do
    CoinGeckoApi.coins_list()
  end

  defp get_currency_list do
    CoinGeckoApi.simple_supported_vs_currencies()
  end

end
