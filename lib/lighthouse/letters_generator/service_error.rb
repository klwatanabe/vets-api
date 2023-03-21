# frozen_string_literal: true

module Lighthouse
  module LettersGenerator
    class ServiceError < StandardError
      attr_accessor :title, :status, :message

      # Expects a response in one of these formats:
      #  { status: "", title: "", detail: "", type: "", instance: "" }
      # OR
      #  { message: "" }
      # @exception Exception [Faraday::ClientError|Faraday::ServerErrror] the exception returned by Faraday middleware
      def initialize(exception = nil)
        super
        unless exception.nil?
          r = exception.response[:body]
          @status ||= r['status']
          @title = r['title'] || exception.class.to_s
          @message = r['detail'] || r['message']
        end
      end
    end
  end
end
