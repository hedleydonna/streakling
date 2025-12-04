class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # If no password provided, skip validation and allow password reset later
    if user_params[:password].blank?
      @user.password = SecureRandom.hex(8) # Temporary password
      @user.password_confirmation = @user.password
      @user.skip_confirmation! if @user.respond_to?(:skip_confirmation!)
    end

    if @user.save
      if user_params[:password].blank?
        redirect_to admin_users_path, notice: "User was successfully created. They will need to reset their password to log in."
      else
        redirect_to admin_users_path, notice: "User was successfully created."
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    # Remove password fields if they're blank to avoid validation errors
    update_params = user_params.dup
    if update_params[:password].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "User was successfully deleted."
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :admin, :current_streak, :longest_streak, :last_completed_date, :daily_points)
  end
end
