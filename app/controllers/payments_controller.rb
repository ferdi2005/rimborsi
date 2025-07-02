class PaymentsController < ApplicationController
  before_action :ensure_admin
  before_action :set_payment, only: %i[ show edit update destroy export_flow mark_as_paid revert_to_created ]

  # GET /payments or /payments.json
  def index
    @payments = Payment.includes(:reimboursements).recent
  end

  # GET /payments/1 or /payments/1.json
  def show
    @available_reimboursements = Reimboursement.payable.includes(:user, :bank_account)
  end

  # GET /payments/new
  def new
    @payment = Payment.new
    @available_reimboursements = Reimboursement.payable.includes(:user, :bank_account)
  end

  # GET /payments/1/edit
  def edit
    unless @payment.can_be_modified?
      redirect_to @payment, alert: "Non puoi modificare un pagamento già eseguito."
      return
    end
    @available_reimboursements = Reimboursement.payable.includes(:user, :bank_account)
  end

  # POST /payments or /payments.json
  def create
    @payment = Payment.new(payment_params)

    respond_to do |format|
      if @payment.save
        format.html { redirect_to @payment, notice: "Pagamento creato con successo." }
        format.json { render :show, status: :created, location: @payment }
      else
        @available_reimboursements = Reimboursement.payable.includes(:user, :bank_account)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payments/1 or /payments/1.json
  def update
    unless @payment.can_be_modified?
      respond_to do |format|
        format.html { redirect_to @payment, alert: "Non puoi modificare un pagamento già eseguito." }
        format.json { render json: { error: "Non autorizzato" }, status: :forbidden }
      end
      return
    end

    respond_to do |format|
      if @payment.update(payment_params)
        format.html { redirect_to @payment, notice: "Pagamento aggiornato con successo." }
        format.json { render :show, status: :ok, location: @payment }
      else
        @available_reimboursements = Reimboursement.payable.includes(:user, :bank_account)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payments/1 or /payments/1.json
  def destroy
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to payments_path, status: :see_other, notice: "Pagamento eliminato con successo." }
      format.json { head :no_content }
    end
  end

  # GET /payments/1/export_flow
  def export_flow
    xml_content = @payment.generate_xml_flow

    send_data xml_content,
              filename: "flusso_pagamento_#{@payment.id}_#{Date.current.strftime('%Y%m%d')}.xml",
              type: 'application/xml',
              disposition: 'attachment'
  end

  # PATCH /payments/1/mark_as_paid
  def mark_as_paid
    begin
      @payment.mark_as_paid!(params[:payment_date]&.to_date || Date.current)
      redirect_to @payment, notice: "Pagamento contrassegnato come eseguito."
    rescue => e
      redirect_to @payment, alert: "Errore: #{e.message}"
    end
  end

  # PATCH /payments/1/revert_to_created
  def revert_to_created
    begin
      @payment.revert_to_created!
      redirect_to @payment, notice: "Pagamento riportato allo stato 'Creato'."
    rescue => e
      redirect_to @payment, alert: "Errore: #{e.message}"
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_payment
    @payment = Payment.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def payment_params
    params.require(:payment).permit(:payment_date, reimboursement_ids: [])
  end
end
