defmodule CryptographWeb.PriceChartLive do
  use CryptographWeb, :live_view
  alias CoinGeckoApi


  @impl true
  def mount(%{"crypto_id" => id, "price_currency" => currency}, _session, socket) do
    schedule_update(5000)
    {:ok, socket
              |> assign(:crypto_id, id)
              |> assign(:currency, currency)
              |> assign(:update_interval, 5000)
              |> assign(:coins_list, get_crypto_ids())
              |> assign(:currency_list, get_currency_list())
              |> push_event("points", %{points: get_simple_price_usd(id, currency), labels: get_datetime()})
              |> push_event("chart-label", %{chart_label: "Current " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})}
  end

  @impl true
  def handle_params(%{"crypto_id" => id, "price_currency" => currency}, _uri, socket) do
    {:noreply, socket
                |> assign(:crypto_id, id)
                |> assign(:currency, currency)
                |> push_event("points", %{points: get_simple_price_usd(id, currency), labels: get_datetime()})
                |> push_event("chart-label", %{chart_label: "Current " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})}
  end

  @impl true
  def handle_event("interval-change",%{"live-chart-select-interval" => interval}, socket) do
    {:noreply, assign(socket, :update_interval, String.to_integer(interval))}
  end

  @impl true
  def handle_event("live-chart", %{"live-chart-select" => selected_id, "live-chart-select-currency" => currency},socket) do
    {:noreply, push_patch(socket, to: Routes.price_chart_path(socket, :index, selected_id, currency))}
  end

  @impl true
  def handle_info(:update, socket) do
    schedule_update(socket.assigns.update_interval)
    {:noreply, socket |> push_event("points", %{points: get_simple_price_usd(socket.assigns.crypto_id, socket.assigns.currency), labels: get_datetime()})}
  end

  def schedule_update(interval), do: self() |> Process.send_after(:update, interval)

  defp get_datetime, do: DateTime.utc_now() |> DateTime.to_string()

  defp get_simple_price_usd(id, currency) do
    price = CoinGeckoApi.simple_price(%{"ids" => id, "vs_currencies" => currency})
    get_in(price, [id, currency])
  end

  defp get_crypto_ids do
    CoinGeckoApi.coins_list()
  end

  defp get_currency_list do
    CoinGeckoApi.simple_supported_vs_currencies()
  end

end
