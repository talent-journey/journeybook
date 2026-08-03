module Journeybook
  class AiStylePrompt < ApplicationRecord
    validates :name, :prompt, presence: true
    validates :name, uniqueness: true
  end
end
