defmodule CryptographWeb.NewsSentimentLive do
  use CryptographWeb, :live_view
  alias Veritaserum
  alias NewsApiClient


  @impl true
  def mount(%{"search_term" => search_term}, _session, socket) do
    articles = get_news_data(search_term)
    headlines = Enum.map(articles, fn x -> x["title"] end)
    {:ok, socket
            |> assign(:search_term, search_term)
            |> assign(:articles, articles )
            |> assign(:sentiment_list, get_sentiment(headlines))
            |> assign(:sentiment, get_avg_sentiment_from_list(headlines))
       }
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
