# frozen_string_literal: true

# Picks a combination of piece-sized article packages that covers at least the
# required amount while minimising package count, then overshoot, then priority.
class ArticlePiecePackageSelector
  def initialize(required_units, articles, immediate_only: false, orderable_only: false)
    @required = required_units
    @articles = articles.select(&:available?).sort_by { [it.priority, -it.quantity] }
    @immediate_only = immediate_only
    @orderable_only = orderable_only
  end

  def select
    return {} if @required <= 0 || @articles.empty?

    search(0, 0, 0, {}, best_holder = { value: nil })
    combination = best_holder[:value]&.fetch(:combination) || {}
    combination.reject { |_, count| count.zero? }
  end

  private

  def search(index, packages_used, units_covered, combination, best_holder)
    if units_covered >= @required
      consider_best(best_holder, packages_used, units_covered, combination)
      return
    end
    return if index >= @articles.length
    return if dominated?(best_holder[:value], packages_used, units_covered)

    article = @articles[index]
    (0..max_packages(article)).each do |count|
      new_combination = combination.merge(article.id => count)
      search(
        index + 1,
        packages_used + count,
        units_covered + (count * article.quantity),
        new_combination,
        best_holder
      )
    end
  end

  def dominated?(best, packages_used, units_covered)
    return false unless best

    packages_used > best[:packages] ||
      (packages_used == best[:packages] && units_covered + max_remaining_units <= best[:units_covered])
  end

  def max_remaining_units
    @articles.sum { max_packages(it) * it.quantity }
  end

  def max_packages(article)
    needed = [(@required + article.quantity - 1) / article.quantity, 0].max
    available =
      if @immediate_only
        article.immediate_packages
      elsif @orderable_only
        article.orderable_packages
      else
        article.max_packages
      end

    return needed if available == Float::INFINITY

    [available, needed].min
  end

  def consider_best(best_holder, packages_used, units_covered, combination)
    candidate = {
      packages: packages_used,
      units_covered: units_covered,
      overshoot: units_covered - @required,
      priority_score: priority_score(combination),
      combination: combination
    }
    current = best_holder[:value]
    best_holder[:value] = candidate if current.nil? || better?(candidate, current)
  end

  def better?(candidate, current)
    (
      [
        candidate[:packages],
        candidate[:overshoot],
        candidate[:priority_score]
      ] <=> [
        current[:packages],
        current[:overshoot],
        current[:priority_score]
      ]
    ) == -1
  end

  def priority_score(combination)
    combination.sum { |article_id, count| article_for(article_id).priority * count }
  end

  def article_for(article_id)
    @articles.find { it.id == article_id }
  end
end
