# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    redirect_to :shots if user_signed_in?

    @shot_count = Shot.active.count
    @user_count = User.count
  end

  def privacy; end
end
