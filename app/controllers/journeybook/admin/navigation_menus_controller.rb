module Journeybook
  module Admin
    class NavigationMenusController < ApplicationController
      before_action :set_menu, only: %i[edit update destroy]

      def index
        @menus = current_site ? current_site.navigation_menus.ordered : NavigationMenu.none
      end

      def new
        @menu = current_site.navigation_menus.build(position: next_position)
      end

      def create
        @menu = current_site.navigation_menus.build(menu_params)

        if @menu.save
          redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation menu created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @items = @menu.items.includes(:page).ordered
      end

      def update
        if @menu.update(menu_params)
          redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation menu updated."
        else
          @items = @menu.items.includes(:page).ordered
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @menu.destroy
        redirect_to admin_navigation_menus_path, notice: "Navigation menu deleted."
      end

      private

      def set_menu
        @menu = NavigationMenu.find(params[:id])
        session[:journeybook_site_id] = @menu.site_id
        @current_site = @menu.site
      end

      def menu_params
        params.require(:navigation_menu).permit(:key, :title, :position)
      end

      def next_position
        current_site.navigation_menus.maximum(:position).to_i + 1
      end
    end
  end
end
