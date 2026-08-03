module Journeybook
  module Admin
    class NavigationItemsController < ApplicationController
      before_action :set_menu
      before_action :set_item, only: %i[edit update destroy move]
      before_action :set_pages, only: %i[new create edit update]

      def new
        @item = @menu.items.build(position: next_position, visible: true)
      end

      def create
        @item = @menu.items.build(item_params)

        if @item.save
          redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation item added."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @item.update(item_params)
          redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation item updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @item.destroy
        redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation item deleted."
      end

      def move
        items = @menu.items.ordered.to_a
        index = items.index(@item)
        other_index = params[:direction] == "up" ? index - 1 : index + 1
        other = items[other_index]

        if other
          NavigationItem.transaction do
            item_position = @item.position
            @item.update!(position: other.position)
            other.update!(position: item_position)
          end
        end

        redirect_to edit_admin_navigation_menu_path(@menu), notice: "Navigation item moved."
      end

      def reorder
        ids = Array(params[:item_ids]).map(&:to_i)
        return head :unprocessable_entity unless ids.sort == @menu.items.pluck(:id).sort

        NavigationItem.transaction do
          ids.each_with_index { |id, position| @menu.items.find(id).update!(position: position) }
        end

        head :no_content
      end

      private

      def set_menu
        @menu = NavigationMenu.find(params[:navigation_menu_id])
        session[:journeybook_site_id] = @menu.site_id
        @current_site = @menu.site
      end

      def set_item
        @item = @menu.items.find(params[:id])
      end

      def set_pages
        @pages = current_site.pages.order(:title)
      end

      def item_params
        params.require(:navigation_item).permit(:page_id, :label, :description, :external_url, :visible, :open_in_new_window)
      end

      def next_position
        @menu.items.maximum(:position).to_i + 1
      end
    end
  end
end
