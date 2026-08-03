module Journeybook
  class PublicPageConstraint
    RESERVED_PATHS = %w[
      /assets/
      /journeybook/
      /rails/
      /recede_historical_location
      /resume_historical_location
      /refresh_historical_location
      /up
    ].freeze

    def matches?(request)
      request.get? && html_request?(request) && RESERVED_PATHS.none? { |path| request.path.start_with?(path) }
    end

    private

    def html_request?(request)
      request.format.html? || request.format == Mime[:all]
    end
  end
end
