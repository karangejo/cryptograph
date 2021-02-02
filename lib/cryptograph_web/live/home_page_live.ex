
defmodule CryptographWeb.HomePageLive do
  use CryptographWeb, :live_view
  alias CoinGeckoApi


  @impl true
  def mount(%{"crypto_id" => id, "price_currency" => currency}, _session, socket) do
    %{description: description, image: image} = get_crypto_info(id)
    ohlc = get_ohlc_data(id, currency)
    mov_av = sma(get_close(ohlc), 10)
    time = get_time(ohlc)
    sma_data = combine_time_data(time, mov_av)
    articles = get_news_data(id)
    headlines = Enum.map(articles, fn x -> x["title"] end)
    schedule_update(5000)
    {:ok, socket
          |> assign(:search_term, id)
          |> assign(:articles, articles)
          |> assign(:sentiment_list, get_sentiment(headlines))
          |> assign(:sentiment, get_avg_sentiment_from_list(headlines))
          |> assign(:crypto_id, id)
          |> assign(:currency, currency)
          |> assign(:description, description)
          |> assign(:image, image)
          |> assign(:update_interval, 5000)
          |> assign(:coins_list, get_crypto_ids())
          |> assign(:currency_list, get_currency_list())
          |> push_event("ohlc-data", %{ohlc_data: ohlc, sma_data: sma_data})
          |> push_event("points", %{points: get_simple_price_usd(id, currency), labels: get_datetime()})
          |> push_event("historical-chart-label", %{chart_label: "Historical " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})
          |> push_event("current-chart-label", %{chart_label: "Current " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})
        }
  end

  @impl true
  def handle_params(%{"crypto_id" => id, "price_currency" => currency}, _uri, socket) do
    %{description: description, image: image} = get_crypto_info(id)
    ohlc = get_ohlc_data(id, currency)
    mov_av = sma(get_close(ohlc), 10)
    time = get_time(ohlc)
    sma_data = combine_time_data(time, mov_av)
    articles = get_news_data(id)
    headlines = Enum.map(articles, fn x -> x["title"] end)
    schedule_update(5000)
    {:noreply, socket
          |> assign(:search_term, id)
          |> assign(:articles, articles)
          |> assign(:sentiment_list, get_sentiment(headlines))
          |> assign(:sentiment, get_avg_sentiment_from_list(headlines))
          |> assign(:crypto_id, id)
          |> assign(:currency, currency)
          |> assign(:description, description)
          |> assign(:image, image)
          |> assign(:update_interval, 5000)
          |> push_event("ohlc-data", %{ohlc_data: ohlc, sma_data: sma_data})
          |> push_event("points", %{points: get_simple_price_usd(id, currency), labels: get_datetime()})
          |> push_event("historical-chart-label", %{chart_label: "Historical " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})
          |> push_event("current-chart-label", %{chart_label: "Current " <> String.capitalize(id) <> " Price in " <> String.upcase(currency)})
        }
  end

  @impl true
  def handle_event("live-chart", %{"live-chart-select" => selected_id, "live-chart-select-currency" => currency},socket) do
    {:noreply, push_patch(socket, to: Routes.home_page_path(socket, :index, selected_id, currency))}
  end

  @impl true
  def handle_event("interval-change",%{"live-chart-select-interval" => interval}, socket) do
    {:noreply, assign(socket, :update_interval, String.to_integer(interval))}
  end


  @impl true
  def handle_event("news-sentiment", %{"news-search-term" => search_term},socket) do
    IO.puts "called"
    {:noreply, push_redirect(socket, to: Routes.news_sentiment_path(socket, :index, search_term))}
  end

  @impl true
  def handle_info(:update, socket) do
    schedule_update(socket.assigns.update_interval)
    {:noreply, socket |> push_event("points", %{points: get_simple_price_usd(socket.assigns.crypto_id, socket.assigns.currency), labels: get_datetime()})}
  end


  def get_ohlc_data(id, currency) do
    CoinGeckoApi.coins_id_ohlc(id, %{"vs_currency" => currency, "days" => "365"})
    |> Enum.map(fn [t, o, h, l, c] -> %{"x" => t, "y" => [o, h, l, c]} end)
  end

  def get_close(ohlc_data) do
     Enum.map(ohlc_data, fn %{"x" => _t, "y" => [_o, _h, _l, c]} -> c end)
  end

  def get_time(ohlc_data) do
     Enum.map(ohlc_data, fn %{"x" => t, "y" => [_o, _h, _l, _c]} -> t end)
  end

  def combine_time_data(time, data) do
    Enum.reverse(Enum.map(Enum.zip(Enum.reverse(time), Enum.reverse(data)), fn {x, y} -> %{"x" => x, "y" => y} end))
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

  defp get_crypto_info(id) do
    data = CoinGeckoApi.coins(id)
    %{description: data["description"]["en"],image: data["image"]["small"]}
  end

  def sma(prices, window) do
    do_sma(Enum.reverse(prices), window, [])
  end

  def do_sma([], _window, acc) do
    acc
  end

  def do_sma(prices, window, acc) do
    {first, _rest} = Enum.split(prices, window)
    if length(first) < window do
      do_sma([], window, acc)
    else
      [_head | tail] = prices
      value = Enum.sum(first) / window
      do_sma(tail, window, [value | acc])
    end
  end

  defp get_news_data(search_term) do
    data = NewsApiClient.everything(%{"q" => search_term})
    data["articles"]
  end

  defp get_sentiment(headline_list) do
      Veritaserum.analyze(headline_list)
  end

  defp get_avg_sentiment_from_list(headline_list) do
    headlines =
      headline_list
      |> Veritaserum.analyze()
      |> Enum.sum()
    headlines / length(headline_list)
  end


end
