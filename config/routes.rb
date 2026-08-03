Journeybook::Engine.routes.draw do
  root "admin/dashboard#show"
  post "form", to: "form_submissions#create", as: :form_submission

  namespace :admin, path: "/" do
    resource :dashboard, only: :show, controller: "dashboard"
    resources :sites, except: :show
    resources :redirects, except: :show
    resources :pages, except: :show do
      member do
        get :source
        patch :source, action: :update_source
        get :preview
        get :errors
        get "component/new", action: :new_component, as: :new_component
        post "component", action: :add_component, as: :add_component
        patch :component
        patch "component/move", action: :move_component, as: :move_component
        patch "component/visibility", action: :toggle_component_visibility, as: :toggle_component_visibility
        patch "components/reorder", action: :reorder_components, as: :reorder_components
        delete "component", action: :delete_component, as: :delete_component
        patch :publish
        patch :draft
        post :duplicate
      end
    end
    resources :navigation_menus, path: "navigation", except: :show do
      resources :navigation_items, only: %i[new create edit update destroy] do
        patch :move, on: :member
        patch :reorder, on: :collection
      end
    end
    resources :components, only: :index
    resources :media_assets, path: "library", except: %i[show edit update]
    get "components/:component/preview", to: "components#preview", as: :component_preview
    resources :ai_style_prompts, path: "ai/styles"
    resource :ai_page, only: %i[new create], path: "ai"
  end
end
