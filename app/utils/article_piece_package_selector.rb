# frozen_string_literal: true

# Picks a combination of piece-sized article packages that covers at least the
# required amount while minimising overshoot, then package count, then priority.
# Overshoot comes first because every unit packed beyond demand is taken from
# another group when stock is short, or bought for nothing when it is not.
# When demand cannot be fully met, returns the combination with the most units
# covered instead (draining available packages for the active only: mode).
#
# Algorithm: depth-first search with backtracking over article types. Articles are
# processed in fixed order (priority ascending, then package size descending).
# At each step the search tries every package count from 0 up to max_packages
# for the current article, then recurses to the next. Whenever units_covered
# meets or exceeds required, the current combination is a candidate. The winning
# combination is the lexicographic minimum by (units covered, package count,
# priority score) — ordering by units covered is the same as ordering by
# overshoot, since required is fixed.
#
# Branch-and-bound pruning, once a covering combination is known, skips a
# subtree that can no longer reach the required amount with the remaining
# articles, and — when the best combination fits exactly — a subtree that has
# already used as many packages as it.
#
# Complexity: let n be the number of available article types and M_i the maximum
# package count tried for article i (stock/order ceiling, capped by
# ceil(required / quantity)). Without pruning the search explores O(∏(M_i + 1))
# combinations; each visited node does O(1) work for the dominance check, so
# worst-case time is O(∏(M_i + 1)). Recursion depth and combination storage
# are O(n). In practice n is small (few pack sizes per ingredient) and pruning
# removes most branches once a good solution exists.
class ArticlePiecePackageSelector
  # Both candidate kinds are ranked by "smallest key wins".
  BEST_KEY = ->(candidate) { [candidate[:units_covered], candidate[:packages], candidate[:priority_score]] }
  PARTIAL_KEY = ->(candidate) { [-candidate[:units_covered], candidate[:packages], candidate[:priority_score]] }

  # Running totals of the combination built so far.
  Tally = Data.define(:packages, :units, :priority) do
    def add(article, count)
      with(packages: packages + count, units: units + (count * article.quantity),
           priority: priority + (count * article.priority))
    end
  end

  def initialize(required_units, articles, only: nil)
    raise ArgumentError, "invalid only: #{only.inspect}" unless ArticleAvailabilityPlanner::RESERVE_ONLY.include?(only)

    @required = required_units
    @articles = articles.select(&:available?).sort_by { [it.priority, -it.quantity] }
    @only = only
    # Article capacity does not change while the search runs (packages are only
    # reserved once select has returned), so these bounds are computed once.
    @max_packages = @articles.to_h { [it.id, packages_available(it)] }
    @max_units_from = max_units_from_each_index
  end

  def select
    return {} if @required <= 0 || @articles.empty?

    @best = nil
    @partial = nil
    search(0, Tally.new(packages: 0, units: 0, priority: 0), {})
    (@best || @partial)&.fetch(:combination) || {}
  end

  private

  def search(index, tally, combination)
    if tally.units >= @required || index >= @articles.length
      record_candidate(tally, combination)
    elsif !dominated?(index, tally)
      branch(index, tally, combination)
    end
  end

  # Tries every package count of the article at index, recursing into the next.
  def branch(index, tally, combination)
    article = @articles[index]
    (0..@max_packages.fetch(article.id)).each do |count|
      combination[article.id] = count unless count.zero?
      search(index + 1, tally.add(article, count), combination)
    end
    combination.delete(article.id)
  end

  # A combination covering the demand competes for best; one that ran out of
  # articles first competes for best partial.
  def record_candidate(tally, combination)
    if tally.units >= @required
      @best = better_of(@best, candidate(tally, combination), BEST_KEY)
    elsif tally.units.positive?
      @partial = better_of(@partial, candidate(tally, combination), PARTIAL_KEY)
    end
  end

  def candidate(tally, combination)
    { packages: tally.packages, units_covered: tally.units, priority_score: tally.priority,
      combination: combination.dup }
  end

  def better_of(current, candidate, key)
    return candidate if current.nil?

    (key.call(candidate) <=> key.call(current)).negative? ? candidate : current
  end

  # Only called while units_covered is still below required, so every candidate
  # below this node needs at least one more package and covers at least required.
  def dominated?(index, tally)
    return false unless @best

    tally.units + @max_units_from[index] < @required ||
      (@best[:units_covered] == @required && tally.packages >= @best[:packages])
  end

  # Element i is the most units the articles from index i on can still add;
  # the last element (past the final article) is 0.
  def max_units_from_each_index
    @articles.reverse_each.with_object([0]) do |article, sums|
      sums.unshift(sums.first + (@max_packages.fetch(article.id) * article.quantity))
    end
  end

  def packages_available(article)
    needed = [(@required / article.quantity).ceil, 0].max # demand is often fractional
    available = article.packages_for(@only)

    return needed if available == Float::INFINITY

    [available, needed].min
  end
end
