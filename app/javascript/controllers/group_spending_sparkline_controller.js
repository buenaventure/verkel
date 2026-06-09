import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"
import {
  budgetDataset,
  chartColors,
  sparklineDataset,
  timelineLabels
} from "../group_spending_chart_helpers"

export default class extends Controller {
  static values = {
    timeline: Array,
    budget: Number
  }

  connect() {
    const canvas = this.element.querySelector('canvas')
    if (!canvas) return

    const colors = chartColors()
    const budget = this.hasBudgetValue ? this.budgetValue : null
    const labels = timelineLabels(this.timelineValue)
    const datasets = [
      sparklineDataset(this.timelineValue, budget, colors),
      budgetDataset(budget, labels.length, colors)
    ].filter(Boolean)

    this.chart = new Chart(canvas, {
      type: 'line',
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        },
        scales: {
          x: { display: false },
          y: { display: false }
        },
        elements: {
          line: { borderWidth: 1.5 }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
