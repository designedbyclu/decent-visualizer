class RoastersController < ApplicationController
  before_action :check_premium!
  before_action :set_roaster, only: %i[ show edit update destroy ]
  before_action :load_roasters, only: %i[index search]

  def index
  end

  def search
    render :index
  end

  def new
    @roaster = current_user.roasters.build
  end

  def edit
  end

  def create
    @roaster = current_user.roasters.build(roaster_params)
    if @roaster.save
      redirect_to roasters_path(format: :html), notice: "Roaster was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @roaster.update(roaster_params)
      redirect_to roasters_path(format: :html), notice: "Roaster was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @roaster.destroy!
    redirect_to roasters_path(format: :html), notice: "Roaster was successfully destroyed."
  end

  private

  def set_roaster
    @roaster = current_user.roasters.find(params[:id])
  end

  def load_roasters
    @roasters = current_user.roasters.by_name.includes(:coffee_bags)
    @roasters = @roasters.where("roasters.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:roaster])}%") if params[:roaster].present?
    @roasters = @roasters.joins(:coffee_bags).where("coffee_bags.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:coffee])}%") if params[:coffee].present?
  end

  def roaster_params
    params.require(:roaster).permit(:name, :website, :image)
  end
end
