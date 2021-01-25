
defmodule CryptographWeb.HomePageLive do
  use CryptographWeb, :live_view
  alias CoinGeckoApi


  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
          |> assign(:coins_list, get_crypto_ids())
          |> assign(:currency_list, get_currency_list()) }
  end

  @impl true
  def handle_event("live-chart", %{"live-chart-select" => selected_id, "live-chart-select-currency" => currency},socket) do
    IO.inspect(currency)
    {:noreply, push_redirect(socket, to: Routes.price_chart_path(socket, :index, selected_id, currency))}
  end

  defp get_crypto_ids do
    CoinGeckoApi.coins_list()
  end

  defp get_currency_list do
    CoinGeckoApi.simple_supported_vs_currencies()
  end

end
