import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"
import {
  budgetDataset,
  chartColors,
  estimatedDataset,
  finalDataset,
  formatEuro,
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
      finalDataset(this.timelineValue, colors),
      estimatedDataset(this.timelineValue, budget, colors),
      budgetDataset(budget, labels.length, colors)
    ].filter(Boolean)

    this.chart = new Chart(canvas, {
      type: 'line',
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { display: true },
          tooltip: {
            callbacks: {
              label: (context) => `${context.dataset.label}: ${formatEuro(context.parsed.y)}`
            }
          }
        },
        scales: {
          x: {
            title: { display: true, text: 'Kiste' }
          },
          y: {
            beginAtZero: true,
            title: { display: true, text: 'Kumulierte Kosten' },
            ticks: {
              callback: (value) => formatEuro(value)
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
