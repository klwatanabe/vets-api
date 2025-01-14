# frozen_string_literal: true

class MessageThreadDetails < Message
  attribute :message_id, Integer
  attribute :thread_id, Integer
  attribute :folder_id, Integer
  attribute :message_body, String
  attribute :draft_date, Common::DateTimeString
  attribute :to_date, Common::DateTimeString
  attribute :has_attachments, Boolean
end
