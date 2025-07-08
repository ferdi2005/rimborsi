class FundsController < ApplicationController
  before_action :set_fund, only: %i[ show edit update destroy ]
  before_action :ensure_admin, only: %i[ show new create edit update destroy ]

  # GET /funds or /funds.json
  def index
    @funds = Fund.all.order(:name)
  end

  # GET /funds/1 or /funds/1.json
  def show
  end

  # GET /funds/new
  def new
    @fund = Fund.new
  end

  # GET /funds/1/edit
  def edit
  end

  # POST /funds or /funds.json
  def create
    @fund = Fund.new(fund_params)

    respond_to do |format|
      if @fund.save
        format.html { redirect_to @fund, notice: "Fondo creato con successo." }
        format.json { render :show, status: :created, location: @fund }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fund.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /funds/1 or /funds/1.json
  def update
    respond_to do |format|
      if @fund.update(fund_params)
        format.html { redirect_to @fund, notice: "Fondo aggiornato con successo." }
        format.json { render :show, status: :ok, location: @fund }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fund.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /funds/1 or /funds/1.json
  def destroy
    @fund.destroy!

    respond_to do |format|
      format.html { redirect_to funds_path, status: :see_other, notice: "Fondo eliminato con successo." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fund
      @fund = Fund.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def fund_params
      params.require(:fund).permit(:name, :budget, :active)
    end
end
