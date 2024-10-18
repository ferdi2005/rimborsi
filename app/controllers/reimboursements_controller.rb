class ReimboursementsController < ApplicationController
  before_action :set_reimboursement, only: %i[ show edit update destroy ]

  # GET /reimboursements or /reimboursements.json
  def index
    @reimboursements = Reimboursement.all
  end

  # GET /reimboursements/1 or /reimboursements/1.json
  def show
  end

  # GET /reimboursements/new
  def new
    @reimboursement = Reimboursement.new
  end

  # GET /reimboursements/1/edit
  def edit
  end

  # POST /reimboursements or /reimboursements.json
  def create
    @reimboursement = Reimboursement.new(reimboursement_params)

    respond_to do |format|
      if @reimboursement.save
        format.html { redirect_to @reimboursement, notice: "Reimboursement was successfully created." }
        format.json { render :show, status: :created, location: @reimboursement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reimboursements/1 or /reimboursements/1.json
  def update
    respond_to do |format|
      if @reimboursement.update(reimboursement_params)
        format.html { redirect_to @reimboursement, notice: "Reimboursement was successfully updated." }
        format.json { render :show, status: :ok, location: @reimboursement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reimboursements/1 or /reimboursements/1.json
  def destroy
    @reimboursement.destroy!

    respond_to do |format|
      format.html { redirect_to reimboursements_path, status: :see_other, notice: "Reimboursement was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reimboursement
      @reimboursement = Reimboursement.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def reimboursement_params
      params.require(:reimboursement).permit(:state_id, :user_id, :bank_account_id, :paypal_account_id)
    end
end
