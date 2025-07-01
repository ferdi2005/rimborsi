class VehiclesController < ApplicationController
  before_action :set_vehicle, only: %i[ show edit update destroy ]

  # GET /vehicles or /vehicles.json
  def index
    if current_user.admin?
      @vehicles = Vehicle.includes(:user).order("users.name", "users.surname")
    else
      @vehicles = current_user.vehicles.order(:name)
    end
  end

  # GET /vehicles/1 or /vehicles/1.json
  def show
  end

  # GET /vehicles/new
  def new
    @vehicle = Vehicle.new
  end

  # GET /vehicles/1/edit
  def edit
  end

  # POST /vehicles or /vehicles.json
  def create
    if current_user.admin? && params[:vehicle][:user_id].present?
      @vehicle = Vehicle.new(vehicle_params)
    else
      @vehicle = current_user.vehicles.build(vehicle_params)
    end

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to @vehicle, notice: "Veicolo creato con successo." }
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vehicles/1 or /vehicles/1.json
  def update
    respond_to do |format|
      if @vehicle.update(vehicle_params)
        format.html { redirect_to @vehicle, notice: "Veicolo aggiornato con successo." }
        format.json { render :show, status: :ok, location: @vehicle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicles/1 or /vehicles/1.json
  def destroy
    @vehicle.destroy!

    respond_to do |format|
      format.html { redirect_to vehicles_path, status: :see_other, notice: "Veicolo eliminato con successo." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle
      if current_user.admin?
        @vehicle = Vehicle.find(params[:id])
      else
        @vehicle = current_user.vehicles.find(params[:id])
      end
    end

    # Only allow a list of trusted parameters through.
    def vehicle_params
      if current_user.admin?
        params.require(:vehicle).permit(:name, :vehicle_category, :fuel_type, :brand, :model, :default, :user_id)
      else
        params.require(:vehicle).permit(:name, :vehicle_category, :fuel_type, :brand, :model, :default)
      end
    end
end
