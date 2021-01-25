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
              |> push_event("points", %{points: get_simple_price_usd(id, currency), labels: get_datetime()})
              |> push_event("chart-label", %{chart_label: "Current " <> String.capitalize(id) <> " Price in " <> currency})}
  end

  @impl true
  def handle_event("interval-change",%{"live-chart-select-interval" => interval}, socket) do
    IO.inspect(interval)
    {:noreply, assign(socket, :update_interval, String.to_integer(interval))}
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

end
