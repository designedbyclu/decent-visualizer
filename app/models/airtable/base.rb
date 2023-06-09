# frozen_string_literal: true

module Airtable
  class Base
    include Communication

    attr_reader :user, :identity

    def initialize(user)
      @user = user
      @table_name = self.class.name.demodulize
      @table_fields = prepare_table_fields
      set_identity
      prepare_table
    end

    private

    def set_identity
      @identity = user.identities.find_by(provider: "airtable")
      raise StandardError.new("Airtable identity not found for User##{user.id}") unless identity
      return if identity.valid_token?

      AirtableRefreshTokenJob.perform_later(identity)
      raise TokenError
    end

    def prepare_table_fields
      raise NotImplementedError
    end
  end
end
