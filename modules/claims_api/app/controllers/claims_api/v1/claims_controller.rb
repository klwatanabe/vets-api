# frozen_string_literal: true

require 'evss/error_middleware'

module ClaimsApi
  module V1
    class ClaimsController < ApplicationController
      include ClaimsApi::PoaVerification
      before_action { permit_scopes %w[claim.read] }
      # before_action :verify_power_of_attorney!, if: :header_request?

      def index
        claims = evss_bgs_services_index
        render json: claims,
               serializer: ActiveModel::Serializer::CollectionSerializer,
               each_serializer: ClaimsApi::ClaimListSerializer
      rescue EVSS::ErrorMiddleware::EVSSError => e
        log_message_to_sentry('Error in claims v1',
                              :warning,
                              body: e.message)
        raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claims not found')
      end

      def show # rubocop:disable Metrics/MethodLength
        claim = ClaimsApi::AutoEstablishedClaim.find_by(id: params[:id])

        if claim && claim.status == 'errored'
          fetch_errored(claim)
        elsif claim && claim.evss_id.blank?
          render json: claim, serializer: ClaimsApi::AutoEstablishedClaimSerializer
        elsif claim && claim.evss_id.present?
          evss_bgs_claim = evss_bgs_services_show(claim.id, claim.evss.id)
          render json: evss_bgs_claim, serializer: ClaimsApi::ClaimDetailSerializer, uuid: claim.id
        elsif /^\d{2,20}$/.match?(params[:id])
          evss_bgs_claim = evss_bgs_services_show(params[:id])
          # NOTE: source doesn't seem to be accessible within a remote evss_bgs_claim
          render json: evss_bgs_claim, serializer: ClaimsApi::ClaimDetailSerializer
        else
          raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claim not found')
        end
      rescue => e
        unless e.is_a?(::Common::Exceptions::ResourceNotFound)
          log_message_to_sentry('Error in claims show',
                                :warning,
                                body: e.message)
        end
        raise if e.is_a?(::Common::Exceptions::UnprocessableEntity)

        raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claim not found')
      end

      private

      def fetch_errored(claim)
        if claim.evss_response&.any?
          errors = format_evss_errors(claim.evss_response)
          raise ::Common::Exceptions::UnprocessableEntity.new(errors:)
        else
          message = 'Unknown EVSS Async Error'
          raise ::Common::Exceptions::UnprocessableEntity.new(detail: message)
        end
      end

      def format_evss_errors(errors)
        errors.map do |error|
          formatted = error['key'] ? error['key'].gsub('.', '/') : error['key']
          { status: 422, detail: "#{error['severity']} #{error['detail'] || error['text']}".squish, source: formatted }
        end
      end

      def evss_bgs_services_index
        # if evss_bgs_service_flipper is true, we are switching over to use BGS, rather than EVSS
        claims = evss_bgs_service_flipper ? find_bgs_claims! : claims_service.all
        evss_bgs_service_flipper ? transform(claims) : claims
      end

      def evss_bgs_services_show(claim_id, evss_claim_id = nil)
        evss_bgs_service_flipper ? claims_service.update_from_remote(evss_claim_id) : find_bgs_claim!(claim_id:)
      end

      def find_bgs_claim!(claim_id:)
        return if claim_id.blank?

        local_bgs_service.find_benefit_claim_details_by_benefit_claim_id(
          claim_id
        )
      end

      def find_bgs_claims!
        local_bgs_service.find_benefit_claims_status_by_ptcpnt_id(
          target_veteran.participant_id
        )
      end

      def transform(claims)
        claims[:benefit_claims_dto][:benefit_claim].map do |claim|
          new_claim = ClaimsApi::V1::EvssLikeClaim.new
          new_claim.add_claim(claim)
          new_claim.list_data
          new_claim
        end
      end
    end
  end
end

module ClaimsApi
  module V1
    class EvssLikeClaim
      attr_reader :evss_id, :list_data, :read_attribute_for_serialization

      def initialize(claim = {})
        @evss_id = nil
        @list_data = add_claim(claim)
      end

      def add_claim(claim)
        @list_data = {}
        @list_data.merge!(claim)
        @list_data.deep_stringify_keys
      end
    end
  end
end
