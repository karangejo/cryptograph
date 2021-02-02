// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import ApexCharts from 'apexcharts'

let hooks = {}
hooks.apexLivePriceChart = {
    mounted() {
        var chartData = []
        var options = {
            series: [{
              name: 'price',
              data: chartData
          }],
            chart: {
            type: 'line',
          },
          animations: {
            enabled: true,
            easing: 'linear',
            dynamicAnimation: {
              speed: 1000
            }
          },
          stroke: {
            curve: 'smooth',
          },
          yaxis: {
            labels: {
              formatter: function (value) {
                return "$" + value;
              }
            },
          },
          title: {
            text: 'Title',
            align: 'left'
          },
          xaxis: {
            type: 'datetime',
            labels: {
                formatter: function (value, timestamp) {
                  return new Date(timestamp).toLocaleTimeString() // The formatter function overrides format property
                } 
            }
          }
          };
  
          var chart = new ApexCharts(this.el, options);
          chart.render();

        const rem_n_first_elements = (num, array) => {
            for(var i = 0; i < num; i++ ){
                array.shift()
            }
            return array
        }

        this.handleEvent("points", ({points, labels}) => {
            let num_to_remove = 0
            if(chartData.length >= 20) {
                num_to_remove = 1
            }
            const updated_points = rem_n_first_elements(num_to_remove, chartData.concat([[Date.parse(labels), points]]))
            chartData = updated_points
            chart.updateSeries([{
                data: updated_points
            }])
        })
        
        this.handleEvent("current-chart-label", ({chart_label}) => {
            chart.updateOptions({
                title: {
                    text: chart_label 
                }
            })
        })

    }

}
hooks.ohlcChart = {
    mounted() {

        var options = {
            series: [
                {
                    name: 'sma',
                    type: 'line',
                    data: []
                },
                {
                    name: 'ohlc',
                    type: 'candlestick',
                    data: []
                }
            ],
            title: {
                 text: 'Title',
                 align: 'left'
            },
            chart: {
                type: 'line'
            },
            stroke: {
                width: [3, 1]
            },
            yaxis: {
                labels: {
                    formatter: function (value) {
                      return "$" + value;
                    }
                },
            },
            xaxis: {
                type: 'datetime'
            }
        }

        var chart = new ApexCharts(this.el, options)
            
        chart.render()
        
        this.handleEvent("ohlc-data", ({ohlc_data, sma_data}) => {
            chart.updateSeries([
                {
                    name: "sma",
                    type: 'line',
                    data: sma_data
                },
                {
                    name: "ohlc",
                    type: 'candlestick',
                    data: ohlc_data
                }
            ])
        })
        
        this.handleEvent("sma-data", ({sma_data}) => {
            chart.updateSeries([{
                name: "sma",
                type: 'line',
                data: sma_data
            }])
        })
        
        this.handleEvent("historical-chart-label", ({chart_label}) => {
            chart.updateOptions({
                title: {
                    text: chart_label 
                }
            })
        })
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

