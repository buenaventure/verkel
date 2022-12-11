# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, :all
    cannot :read, User
    can :manage, :calculation
    can :manage, :dashboard
    can %i[
      packing_lists_articles packing_lists_groups packing_lists_missing_ingredients
      ingredient_meals
      packing_lists_lanes all_packing_lists
      ], Box
    can :packing_list, PackingLaneBox
    can :inventory_list, Article
    if user.laga?
      can %i[laga update_stock], Article
      can %i[deliver store], Order
      can %i[edit_quantities update], Order, state: :delivered # update has special params filter for laga
      can %i[create_stock move_to_stock move_diff_from_stock edit update], PackingLaneBox
    elsif user.office?
      can :manage, :all
      cannot :manage, User
    elsif user.admin?
      can :manage, :all
    end
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
