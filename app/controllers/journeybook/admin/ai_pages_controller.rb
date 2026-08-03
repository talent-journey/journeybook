module Journeybook
  module Admin
    class AiPagesController < ApplicationController
      before_action :set_sites

      def new
        @page = Page.new(site: current_site || @sites.first, locale: current_site&.default_locale || "en", status: "draft")
        set_templates
        set_style_prompts
      end

      def create
        @page = Page.new(page_params)
        @selected_template = template_for(params[:template_key])
        @page.page_type = @selected_template.page_type if @selected_template
        @prompt = params[:prompt].to_s
        @style_prompt = AiStylePrompt.find_by(id: params[:ai_style_prompt_id])
        set_templates
        set_style_prompts

        if @prompt.blank?
          @page.errors.add(:base, "Prompt is required.")
          return render :new, status: :unprocessable_entity
        end

        @page.markdown = Ai::MarkdownGenerator.new(site: @page.site, style_prompt: @style_prompt&.prompt, template: @selected_template).generate(prompt: @prompt)
        add_generation_errors
        render :new
      rescue Ai::OpenaiClient::Error => error
        @page.errors.add(:base, error.message)
        render :new, status: :unprocessable_entity
      end

      private

      def set_sites
        @sites = Site.order(:name)
      end

      def set_style_prompts
        @style_prompts = AiStylePrompt.order(:name)
      end

      def set_templates
        @templates = Journeybook.templates.for_site(@page&.site || current_site || @sites.first)
      end

      def template_for(key)
        return unless key.present?

        Journeybook.templates.for_site(@page.site).find { |template| template.key.to_s == key.to_s }
      end

      def add_generation_errors
        errors = @page.component_validation_errors
        errors.concat(Journeybook::Ai::TemplateValidator.new.errors_for(@page.markdown, @selected_template)) if @selected_template
        errors.uniq.each { |message| @page.errors.add(:markdown, message) }
      end

      def page_params
        params.fetch(:page, {}).permit(:site_id, :title, :path, :meta_title, :meta_description, :status, :locale, :page_type, :excerpt, :author_name, :topic).with_defaults(site_id: current_site&.id, status: "draft", locale: current_site&.default_locale || "en")
      end
    end
  end
end
