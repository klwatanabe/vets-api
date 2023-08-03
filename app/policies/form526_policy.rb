# frozen_string_literal: true

Form526Policy = Struct.new(:user) do
  # Returns a hash mapping User identifiers we require to complete Form 526 to their presence for this user
  # e.g. ["participant_id" => false, "edipi" => true]
  # Included in serialized user profile so front end can identify and display which identifiers are missing
  # Eschewing binary true/false :access? method as in other policies -
  # user needs to share exactly what's missing with the Contact Center
  def form526_required_identifier_presence
    Users::Form526UserIdentificationVerifier.call(user)
  end
end
