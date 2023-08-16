# frozen_string_literal: true

module Lighthouse
  # Custom exception that maps Lighthouse API errors to controller ExceptionHandling-friendly format
  #
  class ServiceException
    include SentryLogging

    # a map of the known Lighthouse errors based on the documentation
    # https://developer.va.gov/
    ERROR_MAP = {
      '504': Common::Exceptions::GatewayTimeout,
      '503': Common::Exceptions::ServiceUnavailable,
      '502': Common::Exceptions::BadGateway,
      '500': Common::Exceptions::ExternalServerInternalServerError,
      '429': Common::Exceptions::TooManyRequests,
      '413': Common::Exceptions::PayloadTooLarge,
      '404': Common::Exceptions::ResourceNotFound,
      '403': Common::Exceptions::Forbidden,
      '401': Common::Exceptions::Unauthorized,
      '400': Common::Exceptions::BadRequest
    }.freeze

    # sends error logs to sentry that contains the client id and url that the consumer was trying call
    # raises an error based off of what the response status was
    # formats the Lighthouse exception for the controller ExceptionHandling to report out to the consumer
    def self.send_error(error, service_name, lighthouse_client_id, url)
      response = error.response
      status_code = get_status_code(response)

      return error unless status_code

      send_error_logs(status_code, error, service_name, lighthouse_client_id, url)

      raise error_class(status_code.to_s.to_sym) if service_gateway_issue?(status_code)

      errors = get_errors_from_response(error, status_code)

      status_code_sym = status_code.to_s.to_sym

      raise error_class(status_code_sym).new(errors:)
    end

    # chooses which error class should be reported based on the http status
    def self.error_class(error_status_sym)
      return Common::Exceptions::ServiceError unless ERROR_MAP.include?(error_status_sym)

      ERROR_MAP[error_status_sym]
    end

    # extracts and transforms Lighthouse errors into the evss_errors schema for the
    # controller ExceptionHandling class
    def self.get_errors_from_response(error, error_status = nil)
      errors = error.response[:body]['errors']

      error_status ||= error.response[:status]

      if errors&.any?
        errors.map do |e|
          status, title, detail, code = error_object_details(e, error_status)

          transform_error_keys(e, status, title, detail, code)
        end
      else
        error_body = error.response[:body]

        status, title, detail, code = error_object_details(error_body, error_status)

        [transform_error_keys(error_body, status, title, detail, code)]
      end
    end

    # error details that match the evss_errors response schema
    # uses known fields in the Lighthouse errors such as "title", "code", "detail", "message", "error"
    # used to get more information from Lighthouse errors in the controllers
    def self.error_object_details(error_body, error_status)
      status = error_status&.to_s
      title = error_body['title'] || error_class(status.to_sym).to_s
      detail = error_body['detail'] ||
               error_body['message'] ||
               error_body['error'] ||
               error_body['error_description'] ||
               'No details provided'

      code = error_body['code'] || error_status&.to_s

      [status, title, detail, code]
    end

    # transform error hash keys into symbols for controller ExceptionHandling class
    def self.transform_error_keys(error_body, status, title, detail, code)
      error_body
        .merge({ status:, code:, title:, detail: })
        .transform_keys(&:to_sym)
    end

    # sends errors to sentry!
    def self.send_error_logs(status_code, error, service_name, lighthouse_client_id, url)
      base_key_string = "#{lighthouse_client_id} #{url} Lighthouse Error"
      Rails.logger.error(
        error.response,
        base_key_string
      )

      Raven.tags_context(
        external_service: service_name
      )

      Raven.extra_context(
        message: error.message,
        url:,
        client_id: lighthouse_client_id
      )

      Raven.capture_exception(error, level: 'warn') if (400..499).include?(status_code)
      Raven.capture_exception(error, level: 'error') if (500..599).include?(status_code)
    end

    def self.get_status_code(response)
      return response.status if response.respond_to?(:status)
      return response[:status] if response.instance_of?(Hash) && response&.key?(:status)
    end

    def self.service_gateway_issue?(status_code)
      # bad gateway, service unavailable, gateway timeout
      [502, 503, 504].include?(status_code)
    end
  end
end
