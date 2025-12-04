class Admin::HabitsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_habit, only: %i[show edit update destroy]

  def index
    @habits = Habit.includes(:user, :streakling_creature).order(created_at: :desc)
  end

  def show
  end

  def new
    @habit = Habit.new
    @habit.build_streakling_creature
  end

  def create
    # Find the user first
    user = User.find_by(id: habit_params[:user_id])
    unless user
      flash.now[:alert] = "Invalid user selected"
      @habit = Habit.new(habit_params.except(:user_id))
      render :new
      return
    end

    # Create habit for that user with nested creature attributes
    @habit = user.habits.build(habit_params.except(:user_id))

    if @habit.save
      creature = @habit.streakling_creature
      redirect_to admin_habits_path, notice: "#{creature.streakling_name} the #{creature.animal_type.capitalize} was born!"
    else
      flash.now[:alert] = "Failed to create habit: #{@habit.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def edit
  end

  def update
    if @habit.update(habit_params)
      redirect_to admin_habits_path, notice: "Habit and creature were successfully updated."
    else
      flash.now[:alert] = "Failed to update habit: #{@habit.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    @habit.destroy
    redirect_to admin_habits_path, notice: "Habit was successfully deleted."
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def set_habit
    @habit = Habit.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:habit_name, :description, :user_id, streakling_creature_attributes: [:id, :streakling_name, :animal_type])
  end
end
