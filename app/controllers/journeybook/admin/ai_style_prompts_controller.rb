module Journeybook
  module Admin
    class AiStylePromptsController < ApplicationController
      before_action :set_style_prompt, only: %i[edit update destroy]

      def index
        @style_prompts = AiStylePrompt.order(:name)
      end

      def new
        @style_prompt = AiStylePrompt.new
      end

      def create
        @style_prompt = AiStylePrompt.new(style_prompt_params)

        if @style_prompt.save
          redirect_to admin_ai_style_prompts_path, notice: "AI style prompt created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @style_prompt.update(style_prompt_params)
          redirect_to admin_ai_style_prompts_path, notice: "AI style prompt updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @style_prompt.destroy
        redirect_to admin_ai_style_prompts_path, notice: "AI style prompt deleted."
      end

      private

      def set_style_prompt
        @style_prompt = AiStylePrompt.find(params[:id])
      end

      def style_prompt_params
        params.require(:ai_style_prompt).permit(:name, :prompt)
      end
    end
  end
end
