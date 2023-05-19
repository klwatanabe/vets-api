# frozen_string_literal: true

module Lighthouse
  module DirectDeposit
    class ErrorResponse
      attr_accessor :status, :errors

      def initialize(status, errors)
        @status = status
        @errors = errors
      end

      def response
        {
          status: @status,
          body:
        }
      end

      def body
        { errors: @errors }
      end

      def code
        errors.first[:code] if errors
      end

      def title
        errors.first[:title] if errors
      end

      def detail
        errors.first[:detail] if errors
      end

      def message
        "#{code}: #{title} - #{detail}"
      end

      def error?
        true
      end
    end
  end
end
