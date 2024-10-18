class FuelsController < ApplicationController
  before_action :set_fuel, only: %i[ show edit update destroy ]

  # GET /fuels or /fuels.json
  def index
    @fuels = Fuel.all
  end

  # GET /fuels/1 or /fuels/1.json
  def show
  end

  # GET /fuels/new
  def new
    @fuel = Fuel.new
  end

  # GET /fuels/1/edit
  def edit
  end

  # POST /fuels or /fuels.json
  def create
    @fuel = Fuel.new(fuel_params)

    respond_to do |format|
      if @fuel.save
        format.html { redirect_to @fuel, notice: "Fuel was successfully created." }
        format.json { render :show, status: :created, location: @fuel }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fuel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fuels/1 or /fuels/1.json
  def update
    respond_to do |format|
      if @fuel.update(fuel_params)
        format.html { redirect_to @fuel, notice: "Fuel was successfully updated." }
        format.json { render :show, status: :ok, location: @fuel }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fuel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fuels/1 or /fuels/1.json
  def destroy
    @fuel.destroy!

    respond_to do |format|
      format.html { redirect_to fuels_path, status: :see_other, notice: "Fuel was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fuel
      @fuel = Fuel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def fuel_params
      params.require(:fuel).permit(:label)
    end
end
