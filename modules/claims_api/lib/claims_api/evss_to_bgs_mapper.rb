# frozen_string_literal: true

module ClaimsApi
  class EvssBgsMapper
    attr_reader :evss_id, :list_data, :read_attribute_for_serialization

    def initialize(claim)
      @data = add_claim(claim)
      @list_data = {}
    end

    def add_claim(claim)
      @data = {}
      @data.merge!(claim)
      @data.deep_stringify_keys
    end

    def map_and_build_object
      claim = EVSSClaim.new
      claim['data']['contention_list'] = @data&.dig('contention_list')
      claim['data']['events_timeline'] = events_timeline
      claim['data']['date_filed'] = @data['claim_dt']
      claim['data']['phase'] = @data['phase_type']
      claim['data']['open'] = @data['phase_type'] != 'complete'
      claim['data']['min_est_date'] = @data['min_est_claim_complete_dt']
      claim['data']['max_est_date'] = @data['max_est_claim_complete_dt']
      claim['data']['waiver_submitted'] = @data['filed5103_waiver_ind']
      claim['data']['claim_type'] = @data['claim_status_type']
      claim['data']['status'] = @data['claim_status']
      claim['list_data'] = @list_data
      claim['evss_id'] = @data['benefit_claim_id']

      # claim['data']['va_representative'] = va_representative
      # claim['data']['development_letter_sent'] = @data['development_letter_sent']
      # claim['data']['decision_letter_sent'] = @data['decision_notification_sent']
      # "documents_needed": false,
      # "requested_decision": null,

      claim
    end

    def events_timeline
      events = [
        create_event_from_string_date(:filed, 'claim_dt'),
        create_event_from_string_date(:phase_chngd_dt, 'phase_chngd_dt')
      ]
      # Make reverse chron with nil date items at the end
      events.compact.sort_by { |h| h[:date] || Date.new }.reverse
    end

    private

    def create_event_from_string_date(type, *from_keys)
      date = @data&.dig(*from_keys)
      return nil unless date

      {
        type:,
        date: DateTime.parse(date).strftime('%m-%d-%Y')
      }
    end
  end
end
