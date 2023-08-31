# frozen_string_literal: true

require 'sidekiq'
require 'bgs'
require 'bgs_service/benefit_claim_service'
require 'bgs_service/claim_management_service'
require 'claims_api/claim_logger'

module ClaimsApi
  class EwsUpdater
    include Sidekiq::Worker
    FILE_5103 = 'Y'
    OMITTED_FIELDS = %w[contentions dvlpmt_items letters name status_messages station_profile stn_suspns_prfil].freeze

    def perform(ews_id)
      ews = ClaimsApi::EvidenceWaiverSubmission.find(ews_id)
      bgs_claim = benefit_claim_service(ews).find_bnft_claim(claim_id: ews.claim_id)

      if bgs_claim&.dig(:bnft_claim_dto, :filed5103_waiver_ind) == FILE_5103
        ews.status = ClaimsApi::EvidenceWaiverSubmission::UPDATED
        ews.save
      else
        bgs_claim[:bnft_claim_dto][:filed5103_waiver_ind] = FILE_5103
        # log here with API-29139
        update_bgs_claim(ews, bgs_claim)
      end
      ews
    end

    private

    def bgs_service(ews)
      BGS::Services.new(external_uid: ews.auth_headers['va_eauth_pnid'],
                        external_key: ews.auth_headers['va_eauth_pnid'])
    end

    def update_claim_level_suspense(ews)
      suspense_claim = claim_management_service(ews).find_claim_level_suspense(claim_id: ews.claim_id)
      updated_claim = update_suspense_date(claim: suspense_claim)
      omitted_claim = omit_fields(updated_claim)
      claim_management_service(ews).update_claim_level_suspense(claim: omitted_claim)
      ews.status = ClaimsApi::EvidenceWaiverSubmission::UPDATED
    rescue => e
      ClaimsApi::Logger.log('ews_updater',
                            detail: "Failed to update suspense dates for claim: #{ews.claim_id},
                            and ews_id: #{ews.id}, with message: #{e.message}.")
      ews.status = ClaimsApi::EvidenceWaiverSubmission::ERRORED
      ews.save
    end

    def omit_fields(claim)
      OMITTED_FIELDS.map do |k|
        claim[:benefit_claim].delete(k.to_sym) if claim[:benefit_claim][k.to_sym].present?
      end
      claim
    end

    def update_suspense_date(claim:)
      claim[:benefit_claim][:clm_suspns_cd] = '053'
      claim[:benefit_claim][:suspns_rsn_txt] = 'Documents uploaded into eFolder'
      current_time = DateTime.now.iso8601(3)
      claim[:benefit_claim][:claim_suspns_dt] = current_time
      claim[:benefit_claim][:suspns_actn_dt] = current_time
      claim
    end

    def benefit_claim_service(ews)
      @bms ||= ClaimsApi::BenefitClaimService.new(external_uid: ews.auth_headers['va_eauth_pnid'],
                                                  external_key: ews.auth_headers['va_eauth_pnid'])
    end

    def claim_management_service(ews)
      @cms ||= ClaimsApi::ClaimManagementService.new(external_uid: ews.auth_headers['va_eauth_pnid'],
                                                     external_key: ews.auth_headers['va_eauth_pnid'])
    end

    def update_bgs_claim(ews, bgs_claim)
      response = bgs_service(ews).benefit_claims.update_bnft_claim(claim: bgs_claim)
      if response[:bnft_claim_dto].nil?
        ews.status = ClaimsApi::EvidenceWaiverSubmission::ERRORED
        ews.bgs_error_message = "BGS Error: update_record failed with code #{response[:return_code]}"
        ews.bgs_upload_failure_count = ews.bgs_upload_failure_count + 1
        ClaimsApi::Logger.log('ews_updater',
                              detail: "Failed to waiver update claim: #{ews.claim_id},
                              and ews: #{ews.id}, with return code: #{response[:return_code]},
                              and failure count: #{ews.bgs_upload_failure_count}.")
      else
        update_claim_level_suspense(ews)
        # Clear out the error message if there were previous failures
        ews.bgs_error_message = nil if ews.bgs_error_message.present?
        ews.status = ClaimsApi::EvidenceWaiverSubmission::UPDATED
        ews.save
        ClaimsApi::Logger.log('ews_updater',
                              detail: "Successfully updated the waiver for
                              claim: #{ews.claim_id}, and ews: #{ews.id}.")
      end
    end
  end
end
