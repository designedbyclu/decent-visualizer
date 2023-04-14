# frozen_string_literal: true

class AirtableShotUploadAllJob < ApplicationJob
  queue_as :default

  def perform(user, shots: nil)
    shots ||= user.shots.where(airtable_id: nil)
    Airtable::ShotSync.new(user).upload_multiple(shots)
  end
end
