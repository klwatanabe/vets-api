# frozen_string_literal: true

require 'sidekiq'

module AppealsApi
  class AppealReceivedJob
    include Sidekiq::Worker
    STATSD_KEY_PREFIX = 'api.appeals.received'
    STATSD_CLAIMANT_EMAIL_SENT = "#{STATSD_KEY_PREFIX}.claimant.email.sent".freeze

    # @param [Hash] opts
    # @option opts [String] :receipt_event The callback indicating which appeal was received. Required.
    # @option opts [Hash] :email_identifier The values identifying the receiving email address. Required
    # @option email_identifier [String] :id_value Either the email or
    #   ICN (Integration Control Number - generated by the Master Patient Index)associated with the appellant. Required.
    # @option email_identifier [String] :id_type The type of id value provided: 'email' or 'ICN'. Required.
    # @option opts [String] :first_name First name of Veteran associated with the appeal. Required.
    # @option opts [Datetime] :date_submitted The date of the appeal's submission. ISO8601 format. Required.
    # @option opts [String] :guid The related appeal's ID. Required.
    # @option opts [String] :claimant_email The non-Veteran claimant's email address.
    # @option opts [String] :claimant_first_name The non-Veteran claimant's first name.

    def perform(opts)
      @opts = opts

      return unless FeatureFlipper.send_email?
      return Rails.logger.error 'AppealReceived: Missing required keys' unless required_keys?

      send(opts['receipt_event'].to_sym)
    end

    def hlr_received
      return unless Flipper.enabled?(:decision_review_hlr_email)

      return log_error(guid, 'HLR') unless valid_email_identifier?

      template_type = 'higher_level_review_received'
      template_name, template_id = template_id(template_type)

      return Rails.logger.error "AppealReceived: could not find template id for #{template_name}" if template_id.blank?

      vanotify_service.send_email(params({ template_id: }))
      StatsD.increment(STATSD_CLAIMANT_EMAIL_SENT, tags: { appeal_type: 'hlr', claimant_type: })
    end

    def nod_received
      return unless Flipper.enabled?(:decision_review_nod_email)

      return log_error(guid, 'NOD') unless valid_email_identifier?

      template_type = 'notice_of_disagreement_received'
      template_name, template_id = template_id(template_type)

      return Rails.logger.error "AppealReceived: could not find template id for #{template_name}" if template_id.blank?

      vanotify_service.send_email(params({ template_id: }))
      StatsD.increment(STATSD_CLAIMANT_EMAIL_SENT, tags: { appeal_type: 'nod', claimant_type: })
    end

    def sc_received
      return unless Flipper.enabled?(:decision_review_sc_email)

      return log_error(guid, 'SC') unless valid_email_identifier?

      template_type = 'supplemental_claim_received'
      template_name, template_id = template_id(template_type)

      return Rails.logger.error "AppealReceived: could not find template id for #{template_name}" if template_id.blank?

      vanotify_service.send_email(params({ template_id: }))
      StatsD.increment(STATSD_CLAIMANT_EMAIL_SENT, tags: { appeal_type: 'sc', claimant_type: })
    end

    private

    attr_accessor :opts

    def vanotify_service
      @vanotify_service ||= VaNotify::Service.new(Settings.vanotify.services.lighthouse.api_key)
    end

    def params(template_opts)
      [
        lookup,
        template_opts,
        personalisation
      ].reduce(&:merge)
    end

    def lookup
      return { email_address: opts['claimant_email'] } if opts['claimant_email'].present?

      if opts['email_identifier']['id_type'] == 'email'
        { email_address: opts['email_identifier']['id_value'] }
      else
        { recipient_identifier: { id_value: opts['email_identifier']['id_value'],
                                  id_type: opts['email_identifier']['id_type'] } }
      end
    end

    def template_id(template)
      t = claimant? ? "#{template}_claimant" : template
      template_id = Settings.vanotify.services.lighthouse.template_id.public_send(t)

      [t, template_id]
    end

    def personalisation
      p = { 'date_submitted' => date_submitted }
      if claimant?
        p['first_name'] = opts['claimant_first_name']
        p['veterans_name'] = opts['first_name']
      else
        p['first_name'] = opts['first_name']
      end
      { personalisation: p }
    end

    def log_error(guid, type)
      Rails.logger.error "No lookup value present for AppealsApi::AppealReceived notification #{type} - GUID: #{guid}"
    end

    def guid
      opts['guid']
    end

    def date_submitted
      @date_submitted ||= DateTime.iso8601(opts['date_submitted']).strftime('%B %d, %Y')
    end

    def valid_email_identifier?
      if claimant?
        opts['claimant_email'].present?
      else
        required_email_identifier_keys.all? { |k| opts.dig('email_identifier', k).present? }
      end
    end

    def claimant?
      opts['claimant_first_name'].present? || opts['claimant_email'].present?
    end

    def claimant_type
      claimant? ? 'non-veteran' : 'veteran'
    end

    def required_email_identifier_keys
      %w[id_type id_value]
    end

    def required_keys?
      required_keys.all? { |k| opts.key?(k) }
    end

    def required_keys
      %w[receipt_event guid email_identifier date_submitted first_name]
    end
  end
end
