# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user
  has_one :airtable_info, dependent: :destroy

  validates :uid, :provider, presence: true
  validates :uid, uniqueness: {scope: :provider} # rubocop:disable Rails/UniqueValidationWithoutIndex

  scope :by_provider, ->(provider) { where(provider:) }

  def valid_token?
    expires_at.nil? || expires_at.future?
  end

  def refresh_token!
    return if valid_token?
    raise "Already refreshing token" if refreshing_token?

    Sidekiq.redis { |r| r.set(refresh_token_key, Time.zone.now.to_s, ex: 300) }
    new_token = OAuth2::AccessToken.new(strategy.client, token, {expires_at: expires_at.to_i, refresh_token:})
    new_token = new_token.refresh!
    update!(token: new_token.token, refresh_token: new_token.refresh_token, expires_at: Time.zone.at(new_token.expires_at))
    Sidekiq.redis { |r| r.del(refresh_token_key) }
  rescue OAuth2::Error => e
    if JSON.parse(e.body)["error"] == "invalid_grant"
      RorVsWild.record_error(e, user_id:)
      destroy!
    end

    raise
  end

  def refreshing_token?
    Sidekiq.redis { |r| r.get(refresh_token_key) }
  end

  private

  def refresh_token_key
    "#{provider}:refreshing_token:#{id}"
  end

  def strategy
    devise_config = Devise.omniauth_configs[provider.to_sym]
    devise_config.strategy_class.new(nil, *devise_config.args)
  end
end

# == Schema Information
#
# Table name: identities
#
#  id            :uuid             not null, primary key
#  blob          :jsonb
#  expires_at    :datetime
#  provider      :string
#  refresh_token :string
#  token         :string
#  uid           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_identities_on_provider_and_uid  (provider,uid) UNIQUE
#  index_identities_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
