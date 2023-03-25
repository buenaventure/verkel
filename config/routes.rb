Rails.application.routes.draw do
  resources :packing_lanes do
    resources :packing_lane_boxes, only: %i[show edit update], shallow: true do
      member do
        post 'create_stock'
        post 'move_diff_from_stock'
        post 'move_to_stock'
        get 'packing_list'
      end
    end
  end
  resources :participants
  resources :diets
  resources :orders do
    member do
      post 'order'
      post 'deliver'
      post 'store'
      post 'cancel'
    end
    resources :order_articles, only: %i[create destroy], shallow: true
    get 'edit_quantities', on: :member
  end
  resources :boxes do
    resources :group_boxes, path: 'groups', as: :group, only: [:show] do
      resources :extra_ingredients, only: %i[new create edit update destroy], shallow: true
      resources :group_box_ingredients, path: 'ingredients', as: :ingredient, only: [:show]
    end
    member do
      get 'packing_lists_groups'
      get 'packing_lists_articles'
      get 'ingredient_meals'
      get 'packing_lists_missing_ingredients'
      get 'packing_lists_lanes'
      get 'all_packing_lists'
    end
  end
  resources :groups do
    resources :group_meal_participations, shallow: true, except: :show, path: 'meal_participations'
    get 'meals_overview', on: :collection
    get 'diets_overview', on: :collection
    resources :meal_selections, only: %i[index create destroy], shallow: true
  end
  devise_for :users
  resources :suppliers
  resources :articles do
    resources :hoards, shallow: true, except: %i[index show]
    get :laga, on: :collection
    post :update_stock, on: :member
    get :inventory_list, on: :collection
  end
  root 'dashboards#show'
  resource :dashboard do
    get 'groups_missing_packing_lane'
    get 'ingredients_missing_article'
    get 'ingredients_without_box'
    get 'recipes_without_content'
    get 'missing_ingredients'
    get 'upcoming_boxes'
    get 'upcoming_order_requirements'
    get 'upcoming_orders'
  end
  resources :meals
  resources :ingredients do
    get 'all', on: :collection
    get 'with_missing_alternatives', on: :collection
    resources :ingredient_alternatives, shallow: true, except: %i[index show]
  end
  resources :recipes do
    get 'kochbuch', on: :collection
  end
  resource :calculation, only: :none do
    post 'demand'
    post 'packing'
  end
  namespace :import do
    root 'imports#show'
    resource :articles, only: :create
    resource :ingredients, only: :create
    resource :participants, only: :create
    resource :groups, only: :create
    resource :diets_ingredients, only: :create
  end
  resources :users, except: :show
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
