# frozen_string_literal: true

module SignIn
  module Redirecting
    extend ActiveSupport::Concern

    included do
      def meta_redirect_to(options = {}, _response_options = {})
        raise ActionController::ActionControllerError, 'Cannot redirect to nil!' unless options
        raise AbstractController::DoubleRenderError if response_body

        self.status        = 200
        self.location      = _compute_redirect_to_location(request, options)
        self.response_body = meta_redirect_body(response.location)
      end
    end

    private

    def meta_redirect_body(location)
      <<-HTML.squish
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta http-equiv="refresh" content="0; url=#{location}">
            <title>Redirecting</title>
          </head>
        </html>
      HTML
    end
  end
end
