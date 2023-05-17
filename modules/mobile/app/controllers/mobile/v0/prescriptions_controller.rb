# frozen_string_literal: true

require 'rx/client'

module Mobile
  module V0
    class PrescriptionsController < ApplicationController
      before_action { authorize :mhv_prescriptions, :access? }

      def index
        begin
          resource = client.get_history_rxs

          # this was recently commended out because it was suspected of causing performance issues due to the nested logging

          # Temporary logging for prescription bug investigation
          # resource.attributes.each do |p|
          #   Rails.logger.info('MHV Prescription Response',
          #                     user: @current_user.uuid,
          #                     params:, id: p[:prescription_id],
          #                     prescription: p)
          # end
        rescue => e
          # pretty sure we can get rid of this now. it was only being used to diagnose unexpected errors. but it's currently logging expected errors,
          # like "optimistic locking errors"
          Rails.logger.error(
            'Mobile Prescription Upstream Index Error',
            resource:, error: e, message: e.message, backtrace: e.backtrace
          )
          raise e
        end

        resource = params[:filter].present? ? resource.find_by(filter_params) : resource
        resource = resource.sort(params[:sort])
        page_resource, page_meta_data = paginate(resource.attributes)

        serialized_prescription = Mobile::V0::PrescriptionsSerializer.new(page_resource, page_meta_data)

        # this was recently commended out because it was suspected of causing performance issues due to the nested logging

        # Temporary logging for prescription bug investigation
        # serialized_prescription.to_hash[:data].each do |p|
        #   Rails.logger.info('Mobile Prescription Response', user: @current_user.uuid, id: p[:id], prescription: p)
        # end

        render json: serialized_prescription
      end

      def refill
        resource = client.post_refill_rxs(ids)

        # this was recently commended out because it was suspected of causing performance issues

        # Temporary logging for prescription bug investigation
        # Rails.logger.info('MHV Prescription Refill Response', user: @current_user.uuid, ids:, response: resource)

        render json: Mobile::V0::PrescriptionsRefillsSerializer.new(@current_user.uuid, resource.body)
      rescue => e
        # this is happening but it mostly seems to be catching this error:
        # "JTA transaction unexpectedly rolled back (maybe due to a timeout"
        # which i assume is a normal and expected error
        # unless we're actively looking at these errors to find something specific, we should remove it
        Rails.logger.error(
          'Mobile Prescription Refill Error',
          resource:, error: e, message: e.message, backtrace: e.backtrace
        )
        raise e
      end

      def tracking
        resource = client.get_tracking_history_rx(params[:id])

        # this was recently commended out because it was suspected of causing performance issues

        # Temporary logging for prescription bug investigation
        # Rails.logger.info('MHV Prescription Tracking Response', user: @current_user.uuid, id: params[:id],
        #                                                         response: resource)

        render json: Mobile::V0::PrescriptionTrackingSerializer.new(resource.data)
      rescue => e
        # this could be helpful but it's mostly just logging expected timeouts
        Rails.logger.error(
          'Mobile Prescription Tracking Error',
          resource:, error: e, message: e.message, backtrace: e.backtrace
        )
        raise e
      end

      private

      def client
        @client ||= Rx::Client.new(session: { user_id: @current_user.mhv_correlation_id }).authenticate
      end

      def pagination_params
        @pagination_params ||= Mobile::V0::Contracts::Prescriptions.new.call(
          page_number: params.dig(:page, :number),
          page_size: params.dig(:page, :size),
          filter: params[:filter].present? ? filter_params.to_h : nil,
          sort: params[:sort]
        )
      end

      def paginate(records)
        Mobile::PaginationHelper.paginate(list: records, validated_params: pagination_params)
      end

      def filter_params
        @filter_params ||= begin
          valid_filter_params = params.require(:filter).permit(Prescription.filterable_attributes)
          raise Common::Exceptions::FilterNotAllowed, params[:filter] if valid_filter_params.empty?

          valid_filter_params
        end
      end

      def ids
        ids = params.require(:ids)
        raise Common::Exceptions::InvalidFieldValue.new('ids', ids) unless ids.is_a? Array

        ids.map(&:to_i)
      end
    end
  end
end
