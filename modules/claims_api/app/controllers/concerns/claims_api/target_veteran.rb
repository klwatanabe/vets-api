# frozen_string_literal: true

require 'rest-client'

module ClaimsApi
  module TargetVeteran
    extend ActiveSupport::Concern

    included do
      def target_veteran
        @target_veteran ||= if @validated_token_payload && @current_user.icn != nil
                              build_target_veteran(veteran_id: @current_user.icn, loa: { current: 3, highest: 3 })
                            elsif user_is_representative?
                              build_target_veteran(veteran_id: params[:veteranId], loa: @current_user.loa)
                            else
                              raise  ::Common::Exceptions::Unauthorized
                            end
      end

      def build_target_veteran(veteran_id:, loa:)
        # rubocop:disable Metrics/MethodLength
        target_veteran ||= ClaimsApi::Veteran.new(
          mhv_icn: veteran_id,
          loa: loa
        )
        # populate missing veteran attributes with their mpi record
        found_record = target_veteran.mpi_record?(user_key: veteran_id)

        unless found_record
          raise ::Common::Exceptions::ResourceNotFound.new(detail:
                                                             "Unable to locate Veteran's ID/ICN in Master Person Index (MPI). " \
            'Please submit an issue at ask.va.gov or call 1-800-MyVA411 (800-698-2411) for assistance.')
        end

        mpi_profile = target_veteran&.mpi&.mvi_response&.profile || {}

        if mpi_profile[:participant_id].blank?
          raise ::Common::Exceptions::UnprocessableEntity.new(detail:
                                                                "Unable to locate Veteran's Participant ID in Master Person Index (MPI). " \
            'Please submit an issue at ask.va.gov or call 1-800-MyVA411 (800-698-2411) for assistance.')
        end

        target_veteran[:first_name] = mpi_profile[:given_names]&.first
        if target_veteran[:first_name].nil?
          raise ::Common::Exceptions::UnprocessableEntity.new(detail: 'Missing first name')
        end

        target_veteran[:last_name] = mpi_profile[:family_name]
        target_veteran[:gender] = mpi_profile[:gender]
        target_veteran[:edipi] = mpi_profile[:edipi]
        target_veteran[:uuid] = mpi_profile[:ssn]
        target_veteran[:ssn] = mpi_profile[:ssn]
        target_veteran[:participant_id] = mpi_profile[:participant_id]
        target_veteran[:last_signed_in] = Time.now.utc
        target_veteran[:va_profile] = ClaimsApi::Veteran.build_profile(mpi_profile.birth_date)
        target_veteran
      end
    end
  end
end
