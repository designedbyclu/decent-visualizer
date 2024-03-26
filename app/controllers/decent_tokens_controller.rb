class DecentTokensController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    decent_token = DecentApi.new(params[:email], params[:password]).login
    if decent_token != "0"
      current_user.update(decent_email: params[:email], decent_token:)
      redirect_to shots_path, notice: "Decent token saved"
    else
      redirect_to new_decent_token_path, alert: {heading: "Invalid email or password", text: "Be sure to use the same email and password you use to log into the Decent website, not Visualizer."}
    end
  end
end
