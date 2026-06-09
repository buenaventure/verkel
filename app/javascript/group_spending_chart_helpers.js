function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

export function chartColors() {
  return {
    success: cssVar('--bs-success') || '#198754',
    warning: cssVar('--bs-warning') || '#ffc107',
    danger: cssVar('--bs-danger') || '#dc3545',
    secondary: cssVar('--bs-secondary') || '#6c757d'
  }
}

export function formatEuro(value) {
  return new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency: 'EUR'
  }).format(value)
}

export function formatDateLabel(isoDate) {
  return new Date(isoDate).toLocaleDateString('de-DE', {
    day: '2-digit',
    month: '2-digit'
  })
}

export function timelineLabels(timeline) {
  return timeline.map((point) => formatDateLabel(point.datetime))
}

export function budgetDataset(budget, labelCount, colors) {
  if (!budget) return null

  return {
    label: 'Budget',
    data: Array(labelCount).fill(budget),
    borderColor: colors.secondary,
    backgroundColor: 'transparent',
    borderDash: [6, 4],
    borderWidth: 2,
    pointRadius: 0,
    tension: 0
  }
}

export function estimatedDataset(timeline, budget, colors) {
  const lastIndex = timeline.length - 1

  return {
    label: 'Kumuliert (geschätzt)',
    data: timeline.map((point) => point.cumulative_total),
    borderColor: colors.warning,
    backgroundColor: 'transparent',
    borderWidth: 2,
    pointBackgroundColor: timeline.map((point, index) => {
      if (index !== lastIndex) return colors.warning
      return budget && point.cumulative_total > budget ? colors.danger : colors.warning
    }),
    pointRadius: 3,
    tension: 0.1
  }
}

export function finalDataset(timeline, colors) {
  return {
    label: 'Kumuliert (endgültig)',
    data: timeline.map((point) => point.cumulative_final),
    borderColor: colors.success,
    backgroundColor: 'transparent',
    borderWidth: 2,
    pointRadius: 3,
    tension: 0.1
  }
}

export function sparklineDataset(timeline, budget, colors) {
  const lastTotal = timeline[timeline.length - 1]?.cumulative_total ?? 0
  const lineColor = budget && lastTotal > budget ? colors.danger : colors.warning

  return {
    data: timeline.map((point) => point.cumulative_total),
    borderColor: lineColor,
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    pointRadius: 0,
    tension: 0.2
  }
}
