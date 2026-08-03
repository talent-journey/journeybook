module Journeybook
  module Admin
    class PagesController < ApplicationController
      before_action :set_page, only: %i[edit update source update_source component new_component add_component move_component toggle_component_visibility reorder_components delete_component destroy preview publish draft duplicate errors]
      before_action :set_sites, only: %i[new edit create update]

      def index
        scope = current_site ? current_site.pages.includes(:site) : Page.none
        scope = scope.by_page_type(params[:type]) if params[:type].present?
        @pages = scope.order(updated_at: :desc)
      end

      def new
        @page = Page.new(site: current_site || Site.order(:name).first, locale: current_site&.default_locale || "en", status: "draft", markdown: starter_markdown)
        @templates = Journeybook.templates.for_site(@page.site)
        @selected_template = template_for(params[:template], @page.site)
        apply_template if @selected_template
      end

      def edit
        set_editor_state
      end

      def source
      end

      def create
        @page = Page.new(page_params)
        template = template_for(params[:template_key], @page.site)
        apply_template_path(template) if template

        if @page.save
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id), notice: "Page created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @page.update(page_params)
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: params[:tab].presence || "settings"), notice: "Page updated."
        else
          set_editor_state
          render :edit, status: :unprocessable_entity
        end
      end

      def update_source
        if @page.update(source_params)
          redirect_to source_admin_page_path(@page, site_id: @page.site_id), notice: "Page source updated."
        else
          render :source, status: :unprocessable_entity
        end
      end

      def component
        component_index = params[:component_index].to_i
        markdown = ComponentTagUpdater.new.update(@page.markdown, component_index, component_props)

        if @page.update(markdown: markdown)
          redirect_params = { site_id: @page.site_id, tab: "layout" }
          redirect_params[:component] = component_index unless params[:save_and_back].present?
          redirect_to edit_admin_page_path(@page, **redirect_params), notice: "Component updated."
        else
          set_sites
          set_editor_state
          render :edit, status: :unprocessable_entity
        end
      rescue IndexError
        redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), alert: "Component not found."
      end

      def new_component
        @components = available_components.sort_by { |component| component.name.to_s }
        @selected_component = component_for(params[:component]) || @components.first
      end

      def add_component
        component = component_for(params[:component_name])

        unless component
          redirect_to new_component_admin_page_path(@page, site_id: @page.site_id), alert: "Component not found."
          return
        end

        component_index = ComponentParser.new.parse(@page.markdown).length
        markdown = ComponentTagUpdater.new.append(@page.markdown, component.name, blank_props(component))

        if @page.update(markdown: markdown)
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout", component: component_index), notice: "Component added."
        else
          @components = available_components
          @selected_component = component
          render :new_component, status: :unprocessable_entity
        end
      end

      def move_component
        markdown = ComponentTagUpdater.new.move(@page.markdown, component_index, params[:direction])

        if @page.update(markdown: markdown)
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), notice: "Component moved."
        else
          set_sites
          set_editor_state
          render :edit, status: :unprocessable_entity
        end
      rescue IndexError
        redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), alert: "Component cannot be moved."
      end

      def reorder_components
        markdown = ComponentTagUpdater.new.reorder(@page.markdown, component_indexes)
        @page.update!(markdown: markdown)

        head :no_content
      rescue ArgumentError
        head :unprocessable_entity
      end

      def toggle_component_visibility
        markdown = ComponentTagUpdater.new.toggle_visibility(@page.markdown, component_index)
        @page.update!(markdown: markdown)

        redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), notice: "Component visibility updated."
      rescue IndexError
        redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), alert: "Component not found."
      end

      def delete_component
        markdown = ComponentTagUpdater.new.delete(@page.markdown, component_index)

        if @page.update(markdown: markdown)
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), notice: "Component deleted."
        else
          set_sites
          set_editor_state
          render :edit, status: :unprocessable_entity
        end
      rescue IndexError
        redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), alert: "Component not found."
      end

      def destroy
        @page.destroy
        redirect_to admin_pages_path(site_id: current_site&.id), notice: "Page deleted."
      end

      def preview
        @journeybook_page = @page
        @journeybook_html = PageRenderer.new.render(
          @page,
          form_authenticity_token: form_authenticity_token,
          component_index: preview_component_index,
          component_anchors: preview_component_index.nil?
        )

        render "journeybook/admin/pages/public_preview", layout: @page.layout_name
      end

      def errors
        @publishing_errors = @page.component_validation_errors
      end

      def publish
        if @page.update(status: "published", published_at: Time.current)
          redirect_to admin_pages_path(site_id: @page.site_id), notice: "Page published."
        else
          redirect_to edit_admin_page_path(@page, site_id: @page.site_id, tab: "layout"), alert: @page.errors.full_messages.to_sentence
        end
      end

      def draft
        @page.update!(status: "draft")
        redirect_to admin_pages_path(site_id: @page.site_id), notice: "Page moved to draft."
      end

      def duplicate
        duplicate = @page.dup
        duplicate.title = duplicate_title
        duplicate.slug = nil
        duplicate.path = duplicate_path
        duplicate.status = "draft"
        duplicate.published_at = nil

        if duplicate.save
          redirect_to edit_admin_page_path(duplicate, site_id: duplicate.site_id), notice: "Page duplicated as a draft."
        else
          redirect_to admin_pages_path(site_id: @page.site_id), alert: duplicate.errors.full_messages.to_sentence
        end
      end

      private

      def set_page
        scope = current_site ? current_site.pages : Page.all
        @page = scope.find(params[:id])
      end

      def set_sites
        @sites = Site.order(:name)
      end

      def set_editor_state
        @editor_tab = params[:tab] == "settings" ? "settings" : "layout"
        @editor_pages = current_site ? current_site.pages.order(:title) : Page.includes(:site).order(:title)
        @page_components = ComponentParser.new.parse(@page.markdown)
        @media_assets = MediaAsset.order(created_at: :desc).limit(24)
        @selected_component_index = params[:component].presence&.to_i
        @selected_component_index = nil unless @selected_component_index && @page_components[@selected_component_index]
        @selected_page_component = @page_components[@selected_component_index] if @selected_component_index
        @selected_component_registration = Journeybook.components.registered(@selected_page_component.name) if @selected_page_component
        @linkable_pages = @page.site.pages.order(:title)
        @parent_pages = @page.site.pages.kb_articles.where.not(id: @page.id).order(:title)
      end

      def page_params
        params.require(:page).permit(:site_id, :title, :path, :markdown, :meta_title, :meta_description, :status, :published_at, :layout, :locale, :page_type, :excerpt, :author_name, :parent_id, :topic, :position)
      end

      def source_params
        params.require(:page).permit(:markdown)
      end

      def component_props
        params.fetch(:component_props, {}).permit!.to_h
      end

      def available_components
        Journeybook.components.for_site(@page.site).to_a
      end

      def component_for(name)
        available_components.find { |component| component.name.to_s == name.to_s }
      end

      def blank_props(component)
        component.normalized_props.transform_values { "" }
      end

      def component_index
        params[:component_index].to_i
      end

      def component_indexes
        Array(params[:component_indexes]).map(&:to_i)
      end

      def preview_component_index
        Integer(params[:component], exception: false)
      end

      def starter_markdown
        "{{ hero }}"
      end

      def template_for(key, site)
        return unless key.present?

        Journeybook.templates.for_site(site).find { |template| template.key.to_s == key.to_s }
      end

      def apply_template
        @page.page_type = @selected_template.page_type
        @page.markdown = @selected_template.markdown
      end

      def apply_template_path(template)
        return unless template

        @page.page_type = template.page_type
        return unless template.path_prefix && @page.path.blank?

        @page.path = "#{template.path_prefix}/#{@page.title.to_s.parameterize}"
      end

      def duplicate_title
        base = "Copy of #{@page.title}"
        return base unless @page.site.pages.where(locale: @page.locale, title: base).exists?

        suffix = 2
        loop do
          title = "#{base} (#{suffix})"
          return title unless @page.site.pages.where(locale: @page.locale, title: title).exists?

          suffix += 1
        end
      end

      def duplicate_path
        base = @page.path == "/" ? "/#{@page.slug.presence || @page.title.parameterize}" : @page.path
        candidate = "#{base}-copy"
        suffix = 2

        while @page.site.pages.where(locale: @page.locale, path: candidate).exists?
          candidate = "#{base}-copy-#{suffix}"
          suffix += 1
        end

        candidate
      end
    end
  end
end
