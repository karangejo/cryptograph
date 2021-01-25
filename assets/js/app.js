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
import Chart from 'chart.js'
import ApexCharts from 'apexcharts'

let hooks = {}
hooks.apexLivePriceChart = {
    mounted() {
        var chartData = []
        var options = {
            series: [{
              data: chartData
          }],
            chart: {
            type: 'line',
          },
          title: {
            text: 'Title',
            align: 'left'
          },
          xaxis: {
            type: 'datetime'
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
            console.log(updated_points)
            chart.updateSeries([{
                data: updated_points
            }])
        })

    }

}
hooks.livePriceChart = {
    mounted() {
        var ctx = this.el.getContext('2d'); 
        var chart = new Chart(ctx, {
        // The type of chart we want to create
        type: 'line',
        // The data for our dataset
        data: {
            labels: [],
            datasets: [{
                label: 'price',
                data: [],
                borderColor: '#3F3FBF'
            }]
        },
        // Configuration options go here
        options: {
            responsive: true,
            maintainAspectRatio: false,
            title: {
                display: true,
                text: "A TITLE"
            },
            scales: {
                yAxes: [{
                    ticks: {
                        callback: function(value, index, values) {
                            return "$" + value
                        }
                    }
                }],
                xAxes: [{
                    ticks: {
                        callback: function(value, index, values) {
                            let date =  new Date(value)
                            return date.toLocaleTimeString()
                        }
                    }
                }]
            }
        }
        });

        const rem_n_first_elements = (num, array) => {
            for(var i = 0; i < num; i++ ){
                array.shift()
            }
            return array
        }

        this.handleEvent("points", ({points, labels}) => {
            let num_to_remove = 0
            if(chart.data.datasets[0].data.length >= 20) {
                num_to_remove = 1
            }
            const updated_points = rem_n_first_elements(num_to_remove, chart.data.datasets[0].data.concat(points))
            const updated_labels = rem_n_first_elements(num_to_remove, chart.data.labels.concat(labels))
            chart.data.datasets[0].data = updated_points
            chart.data.labels = updated_labels
            chart.update()
        })
        
        this.handleEvent("chart-label", ({chart_label}) => {
            chart.options.title.text = chart_label
            chart.update()
        })

    }

}

hooks.ohlcChart = {
    mounted() {

        this.handleEvent("ohlc-data", ({ohlc_data}) => {
            var options = {
                chart: {
                    type: 'candlestick'
                },
                series: [{
                    data: ohlc_data
                }],
                xaxis: {
                    type: 'datetime'
                }
            }

            var chart = new ApexCharts(this.el, options)
            chart.render()
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

