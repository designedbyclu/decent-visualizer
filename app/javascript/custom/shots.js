import Chart from "chart.js"
require("chartjs-plugin-crosshair/src/index.js")
require("chartjs-plugin-annotation")

const chartOptions = {
  scales: {
    xAxes: [{
      type: "time",
      time: {
        displayFormats: {
          second: "ss.SS[s]"
        },
        tooltipFormat: "ss.SS[s]",
      },
      distribution: "series",
      offset: true,
      ticks: {
        source: "data",
        autoSkip: true,
        autoSkipPadding: 50,
        maxRotation: 0
      },
      gridLines: {
        display: false
      }
    }],
    yAxes: [{
      gridLines: {
        color: "rgba(128, 128, 128, 0.35)"
      }
    }]
  },
  plugins: {
    crosshair: {
      line: {
        color: "rgba(128, 128, 128, 1)",
        dashPattern: [5, 5]
      },
    },
  },
  tooltips: {
    intersect: false,
    mode: "index",
    callbacks: {
      label: function (tooltipItem, myData) {
        let label = myData.datasets[tooltipItem.datasetIndex].label || ""
        if (label) {
          label += ": "
        }
        label += parseFloat(tooltipItem.value).toFixed(2)
        return label
      }
    }
  }
}

function getColors() {
  const colors = {
    classic: {
      "espresso_pressure": { title: "Pressure (bar)", borderColor: "rgba(5, 199, 147, 1)", backgroundColor: "rgba(5, 199, 147, 0.7)", borderDash: [], fill: true, hidden: false },
      "espresso_pressure_goal": { title: "Pressure Goal (bar)", borderColor: "rgba(3, 99, 74, 1)", backgroundColor: "rgba(3, 99, 74, 1)", borderDash: [5, 5], fill: false, hidden: false },
      "espresso_water_dispensed": { title: "Water Dispensed (ml)", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false },
      "espresso_weight": { title: "Weight (g)", borderColor: "rgba(143, 100, 0, 1)", backgroundColor: "rgba(143, 100, 0, 0.7)", borderDash: [], fill: true, hidden: true },
      "espresso_flow": { title: "Flow (ml/s)", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false },
      "espresso_flow_weight": { title: "Weight (g/s)", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 0.7)", borderDash: [], fill: true, hidden: false },
      "espresso_flow_weight_raw": { title: "Weight (g/s) Raw", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 1)", borderDash: [], fill: false, hidden: false },
      "espresso_flow_goal": { title: "Flow Goal (ml/s)", borderColor: "rgba(9, 72, 93, 1)", backgroundColor: "rgba(9, 72, 93, 1)", borderDash: [5, 5], fill: false, hidden: false },
      "espresso_resistance": { title: "Resistance (lΩ)", borderColor: "rgba(229, 229, 0, 1)", backgroundColor: "rgba(229, 229, 0, 1)", borderDash: [], fill: false, hidden: false },
      "espresso_temperature_basket": { title: "Temperature Basket °C", borderColor: "e73249", backgroundColor: "rgba(240, 86, 122, 0.7)", borderDash: [], fill: false, hidden: false },
      "espresso_temperature_mix": { title: "Temperature Mix °C", borderColor: "rgba(206, 18, 62, 1)", backgroundColor: "rgba(206, 18, 62, 0.7)", borderDash: [], fill: false, hidden: false },
      "espresso_temperature_goal": { title: "Temperature Goal °C", borderColor: "rgba(150, 13, 45, 1)", backgroundColor: "rgba(150, 13, 45, 0.7)", borderDash: [5, 5], fill: false, hidden: false },
    },
    dsx: {
      "espresso_pressure": { title: "Pressure (bar)", borderColor: "#18c37e", backgroundColor: "#18c37e", borderDash: [], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_pressure_goal": { title: "Pressure Goal (bar)", borderColor: "#69fdb3", backgroundColor: "#69fdb3", borderDash: [5, 5], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_weight": { title: "Weight (g)", borderColor: "#a2693d", backgroundColor: "#a2693d", borderDash: [], fill: false, hidden: true, borderWidth: 0, lineTension: 0 },
      "espresso_flow": { title: "Flow (ml/s)", borderColor: "#4e85f4", backgroundColor: "#4e85f4", borderDash: [], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_flow_weight": { title: "Weight (g/s)", borderColor: "#a2693d", backgroundColor: "#a2693d", borderDash: [], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_flow_goal": { title: "Flow Goal (ml/s)", borderColor: "#7aaaff", backgroundColor: "#7aaaff", borderDash: [5, 5], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_resistance": { title: "Resistance (lΩ)", borderColor: "#e5e500", backgroundColor: "#e5e500", borderDash: [], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_temperature_basket": { title: "Temperature Basket °C", borderColor: "#e73249", backgroundColor: "#e73249", borderDash: [], fill: false, borderWidth: 1, lineTension: 0 },
      "espresso_temperature_mix": { title: "Temperature Mix °C", borderColor: "#ff9900", backgroundColor: "#ff9900", borderDash: [], fill: false, hidden: false, borderWidth: 1, lineTension: 0 },
      "espresso_temperature_goal": { title: "Temperature Goal °C", borderColor: "#e73249", backgroundColor: "#e73249", borderDash: [5, 5], fill: false, borderWidth: 1, lineTension: 0 },
    }
  }
  return colors[selectedSkin]
}

let mainChart, temperatureChart, selectedSkin;

function chartFromData(data) {
  const colors = getColors()
  return data.map(function (v) {
    if (v.label in colors) {
      const current = colors[v.label]
      return {
        label: current.title,
        data: v.data,
        title: current.title,
        borderColor: current.borderColor,
        backgroundColor: current.backgroundColor,
        borderDash: current.borderDash,
        fill: current.fill,
        hidden: current.hidden,
        borderWidth: current.borderWidth,
        lineTension: current.lineTension,
        pointRadius: 0,
      }
    }
  }).filter(e => e)
}

function annotationsFromData(stages) {
  return stages.map(function (v) {
    return {
      type: "line",
      mode: "vertical",
      scaleID: "x-axis-0",
      value: v,
      borderColor: "rgba(128, 128, 128, 1)"
    }
  })
}

function drawChart() {
  selectSkin()
  const ctx = document.getElementById("mainChart").getContext("2d")
  const annotations = {
    annotation: {
      annotations: annotationsFromData(window.shotStages)
    }
  }
  const options = {
    ...chartOptions,
    ...annotations
  }
  mainChart = new Chart(ctx, {
    type: "line",
    data: { datasets: chartFromData(window.mainData) },
    options: options
  })
  const tctx = document.getElementById("temperatureChart").getContext("2d")
  temperatureChart = new Chart(tctx, {
    type: "line",
    data: { datasets: chartFromData(window.temperatureData) },
    options: options
  })
}

function setURLSkin(skin) {
  let queryParams = new URLSearchParams(window.location.search)
  queryParams.set("skin", skin)
  history.replaceState(null, null, "?" + queryParams.toString())
}

function selectSkin() {
  if (document.getElementById("checkbox-skin-dsx").checked) {
    document.getElementsByTagName("body")[0].classList.add("black")
    selectedSkin = "dsx"
    setURLSkin("dsx")
  } else if (document.getElementById("checkbox-skin-white-dsx").checked) {
    document.getElementsByTagName("body")[0].classList.remove("black")
    selectedSkin = "dsx"
    setURLSkin("white-dsx")
  } else {
    document.getElementsByTagName("body")[0].classList.remove("black")
    selectedSkin = "classic"
    setURLSkin("classic")
  }
}

document.addEventListener("turbolinks:load", function () {
  if (document.getElementById("skin-picker")) {
    drawChart()
    document.getElementById("skin-picker").addEventListener("change", function () {
      mainChart.destroy()
      temperatureChart.destroy()
      drawChart()
    })
  }
})
