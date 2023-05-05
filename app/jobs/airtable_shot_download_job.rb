# frozen_string_literal: true

class AirtableShotDownloadJob < ApplicationJob
  queue_as :default

  def perform(user, minutes: 60)
    Airtable::Shot.new(user).download(minutes:)
  end
end
