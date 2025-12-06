class Admin::StagesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_stage, only: %i[show edit update]

  def index
    @stages = Stage.ordered
  end

  def show
  end

  def edit
  end

  def update
    if @stage.update(stage_params)
      redirect_to admin_stages_path, notice: "Stage updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :min_streak, :max_streak, :default_message, :emoji, :display_order)
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end
end

