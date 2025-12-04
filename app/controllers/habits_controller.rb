class HabitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit, only: %i[ show edit update destroy toggle ]
  before_action :authorize_habit_owner, only: %i[ show edit update destroy toggle ]

  # GET /habits or /habits.json
  def index
    @habits = Habit.all
  end

  # GET /habits/1 or /habits/1.json
  def show
  end

  # GET /habits/new
  def new
    @habit = current_user.habits.build
  end

  # GET /habits/1/edit
  def edit
  end

  # POST /habits or /habits.json
  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      creature = @habit.streakling_creature
      redirect_to dashboard_path, notice: "#{creature.streakling_name} the #{creature.animal_type.capitalize} was born!"
    else
      render :new
    end
  end

  # PATCH/PUT /habits/1 or /habits/1.json
  def update
    @habit = current_user.habits.find(params[:id])

    if @habit.update(habit_params)
      redirect_to dashboard_path, notice: "Your Streakling is happy with the changes!"
    else
      render :edit
    end
  end

  # DELETE /habits/1 or /habits/1.json
  def destroy
    @habit.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "Habit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def toggle
    @habit = current_user.habits.find(params[:id])

    if @habit.completed_today?
      # Un-check it (rare, but allowed)
      @habit.update(completed_on: nil)
    else
      # Check it off → this is what makes your creature grow!
      @habit.update(completed_on: Time.zone.today)
    end

    # THIS IS THE MAGIC LINE — grows or regresses the creature
    @habit.streakling_creature.update_streak_and_mood!

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Habit updated — your Streakling feels it!" }
      format.turbo_stream
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit
      @habit = Habit.find(params[:id])
    end

    def authorize_habit_owner
      unless @habit.user == current_user
        redirect_to root_path, alert: "You can only access your own habits."
      end
    end

    # Only allow a list of trusted parameters through.
    def habit_params
      params.require(:habit).permit(:habit_name, :description, streakling_creature_attributes: [:id, :streakling_name, :animal_type])
    end
end
