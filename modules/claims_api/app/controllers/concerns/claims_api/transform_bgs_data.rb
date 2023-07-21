# frozen_string_literal: true

require 'claims_api/bgs_claim_status_mapper'

module ClaimsApi
  module TransformBGSData
    def get_bgs_phase_completed_dates(data)
      sym_data = data.each(&:deep_symbolize_keys!)
      lc_status_array = if sym_data.is_a?(Hash)
                          [sym_data&.dig(:benefit_claim_details_dto, :bnft_claim_lc_status)].flatten.compact
                        else
                          sym_data
                        end
      return {} if lc_status_array.first.nil?

      max_completed_phase = lc_status_array.first[:phase_type_change_ind].chars.first
      return {} if max_completed_phase.downcase.eql?('n')

      {}.tap do |phase_date|
        lc_status_array.reverse.map do |phase|
          completed_phase_number = phase[:phase_type_change_ind].chars.first

          if completed_phase_number <= max_completed_phase &&
             completed_phase_number.to_i.positive?
            phase_date["phase#{completed_phase_number}CompleteDate"] = date_present(phase[:phase_chngd_dt])
          end
        end
      end.sort.reverse.to_h
    end

    ## called from inside of format_bgs_phase_date & format_bgs_phase_chng_dates
    ## calls format_bgs_date
    def date_present(date)
      return unless date.is_a?(Date) || date.is_a?(String)

      date.present? ? format_bgs_date(date) : nil
    end

    def format_bgs_date(phase_change_date)
      d = Date.parse(phase_change_date.to_s)
      d.strftime('%Y-%m-%d')
    end

    def detect_current_status(data)
      data.deep_symbolize_keys!

      if data[:bnft_claim_lc_status].nil? && data.exclude?(:claim_status) && data.exclude?(:phase_type)
        return 'NO_STATUS_PROVIDED'
      end

      phase_data = if 
        # !data&.dig(:bnft_claim_lc_status, :phase_type).nil?
        #              data&.dig(:bnft_claim_lc_status, :phase_type)
                    data[:phase_type].present?
                     data[:phase_type]
                   elsif data[:bnft_claim_lc_status].present?
                     data[:bnft_claim_lc_status]
                   else
                     data[:claim_status]
                   end

      return bgs_phase_status_mapper.name(phase_data) if phase_data.is_a?(String)

      phase_data.is_a?(Array) ? cast_claim_lc_status(phase_data) : get_current_status_from_hash(phase_data)
    end

    # The status can either be an object or array
    # This picks the most recent status from the array
    def cast_claim_lc_status(phase_data)
      return if phase_data.blank?

      phase = [phase_data].flatten.max do |a, b|
        a[:phase_chngd_dt] <=> b[:phase_chngd_dt]
      end
      phase_number = get_completed_phase_number_from_phase_details(phase_data.last)
      bgs_phase_status_mapper.name(phase[:phase_type], phase_number || nil)
    end

    def map_yes_no_to_boolean(key, value)
      # Requested decision appears to be included in the BGS payload
      # only when it is yes. Assume an ommission is akin to no, i.e., false
      return false if value.blank?

      case value.downcase
      when 'yes', 'y' then true
      when 'no', 'n' then false
      else
        Rails.logger.error "Expected key '#{key}' to be Yes/No. Got '#{s}'."
        nil
      end
    end

    def get_current_status_from_hash(data)
      if data&.dig('benefit_claim_details_dto', 'bnft_claim_lc_status').present?
        data[:benefit_claim_details_dto][:bnft_claim_lc_status].last do |lc|
          phase_number = get_completed_phase_number_from_phase_details(lc)
          bgs_phase_status_mapper.name(lc[:phase_type], phase_number || nil)
        end
      elsif data&.dig(:phase_type).present?
        bgs_phase_status_mapper.name(data[:phase_type])
      end
    end

    def get_completed_phase_number_from_phase_details(details)
      if details[:phase_type_change_ind].present?
        return if details[:phase_type_change_ind] == 'N'

        details[:phase_type_change_ind].chars.first
      end
    end

    private

    def bgs_phase_status_mapper
      ClaimsApi::BGSClaimStatusMapper.new
    end
  end
end
