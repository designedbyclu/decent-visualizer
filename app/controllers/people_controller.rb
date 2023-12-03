# frozen_string_literal: true

class PeopleController < ApplicationController
  include CursorPaginatable

  def show
    @user = User.find_by(slug: params[:id])

    if @user.nil?
      @user = User.find_by(id: params[:id])
      return redirect_to community_index_path, alert: "User #{params[:id]} was not found" if @user.nil?
      return redirect_to person_path(id: @user.slug), status: :moved_permanently if @user.public?
    end

    if @user.public
      @shots = @user.shots
      unless current_user&.premium?
        @premium_count = @shots.premium.count
        @shots = @shots.non_premium
      end
      @shots, @cursor = paginate_with_cursor(@shots, by: :start_time, before: params[:before])
    else
      redirect_to :root
    end
  end

  def feed
    @user = User.find_by(slug: params[:id])

    if @user.nil?
      @user = User.find_by(id: params[:id])
      return head :not_found if @user.nil?
      return redirect_to feed_person_path(id: @user.slug), status: :moved_permanently if @user.public?
    end

    if @user&.public
      @shots = @user.shots.by_start_time.non_premium.limit(30)
    else
      head :not_found
    end

    render formats: :rss
  end
end
