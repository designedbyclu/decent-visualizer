# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

  FILTERS = {
    profile_title: {autocomplete: true},
    bean_brand: {autocomplete: true},
    bean_type: {autocomplete: true},
    user: {autocomplete: true, target: :user_id},
    grinder_model: {autocomplete: true},
    roast_level: {autocomplete: true},
    bean_notes: {},
    espresso_notes: {}
  }.freeze

  def index
    if params[:commit]
      @shots = Shot.visible_or_owned_by_id(current_user&.id).by_start_time.includes(:user)
      FILTERS.each do |filter, options|
        next if params[filter].blank?

        @shots = if options[:target]
          find_user_by_name if filter == :user && params[options[:target]].blank?
          @shots.where(options[:target] => params[options[:target]])
        else
          @shots.where("#{filter} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[filter])}%")
        end
      end
      @shots = @shots.where("espresso_enjoyment >= ?", params[:min_enjoyment]) if params[:min_enjoyment].to_i.positive?
      @shots = @shots.where("espresso_enjoyment <= ?", params[:max_enjoyment]) if params[:max_enjoyment].present? && params[:max_enjoyment].to_i < 100

      unless current_user&.premium?
        @premium_count = @shots.count - @shots.non_premium.count
        @shots = @shots.non_premium
      end
      @pagy, @shots = pagy_countless(@shots)
    elsif current_user.blank?
      @shots = Shot.visible.by_start_time.includes(:user).non_premium
      @pagy, @shots = pagy_countless(@shots)
    else
      @shots = []
    end
  end

  def autocomplete
    @filter = params[:filter].to_sym
    @values = values_for_query(@filter, params[:q])
    render layout: false
  end

  def unique_values_for(filter)
    if filter == :user
      User.visible_or_id(current_user&.id).by_name
    else
      Rails.cache.read("unique_values_for_#{filter}")
    end
  end

  private

  def find_user_by_name
    user = values_for_query(:user, params[:user]).first
    return if user.nil?

    params[:user_id] = user.id
    params[:user] = user.display_name
  end

  def values_for_query(filter, query)
    query_parts = query.split(/\s+/).map { |q| Regexp.escape(q) }
    rquery = /#{query_parts.join(".*")}/i
    values = unique_values_for(filter)
    return [] if values.blank?

    if filter == :user
      values.select { |u| u.display_name =~ rquery }
    else
      values.grep(rquery)
    end
  end
end
