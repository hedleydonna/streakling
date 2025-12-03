class HabitsController < ApplicationController
  before_action :set_habit, only: %i[ show edit update destroy ]

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
    @habit = current_user.habits.new(habit_params)   # ← this line sets user_id automatically
  
    if @habit.save
      redirect_to root_path, notice: "Habit added! Feed your critter!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /habits/1 or /habits/1.json
  def update
    respond_to do |format|
      if @habit.update(habit_params)
        format.html { redirect_to @habit, notice: "Habit was successfully updated." }
        format.json { render :show, status: :ok, location: @habit }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @habit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /habits/1 or /habits/1.json
  def destroy
    @habit.destroy!

    respond_to do |format|
      format.html { redirect_to habits_path, status: :see_other, notice: "Habit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def toggle
    @habit = current_user.habits.find(params[:id])
    @habit.toggle_today!
    redirect_to root_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit
      @habit = Habit.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def habit_params
      params.require(:habit).permit(:name, :emoji, :user_id)
    end
end
