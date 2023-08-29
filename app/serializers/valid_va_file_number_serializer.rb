# frozen_string_literal: true

class ValidVAFileNumberSerializer < ActiveModel::Serializer
  type :valid_va_file_number

  attribute :valid_va_file_number
  attribute :file_nbr_matches_ssn

  def id
    nil
  end

  def valid_va_file_number
    object[:file_nbr]
  end

  def file_nbr_matches_ssn
    object[:file_nbr_matches_ssn]
  end
end
