class Admin::PaymentsController < ApplicationController
  before_action :ensure_admin
  before_action :set_payment, only: %i[ show edit update destroy export_flow mark_as_paid revert_to_created retry ]

  # GET /admin/payments/1 or /admin/payments/1.json
  def show
    @available_reimboursements = Reimboursement.payable.where(payment_id: nil).where.not(bank_account: nil).includes(:user, :bank_account)
  end

  # GET /admin/payments/new
  def new
    @payment = Payment.new
    @available_reimboursements = Reimboursement.payable.where(payment_id: nil).where.not(bank_account: nil).includes(:user, :bank_account)
  end

  # GET /admin/payments/1/edit
  def edit
    unless @payment.can_be_modified?
      redirect_to [ :admin, @payment ], alert: "Non puoi modificare un pagamento già eseguito."
      return
    end
    @available_reimboursements = Reimboursement.payable.where(payment_id: nil).includes(:user, :bank_account)
  end

  # GET /payments or /payments.json
  def index
    @payments = Payment.includes(:reimboursements).recent
  end


  # POST /payments or /payments.json
  def create
    @payment = Payment.new(payment_params.except(:reimboursement_ids))

    respond_to do |format|
      if @payment.save
        # Associa i rimborsi selezionati al pagamento
        update_payment_reimboursements(@payment, payment_params[:reimboursement_ids])
        format.html { redirect_to [ :admin, @payment ], notice: "Pagamento creato con successo." }
        format.json { render :show, status: :created, location: [ :admin, @payment ] }
      else
        @available_reimboursements = Reimboursement.payable.where(payment_id: nil).includes(:user, :bank_account)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payments/1 or /payments/1.json
  def update
    unless @payment.can_be_modified?
      respond_to do |format|
        format.html { redirect_to [ :admin, @payment ], alert: "Non puoi modificare un pagamento già eseguito." }
        format.json { render json: { error: "Non autorizzato" }, status: :forbidden }
      end
      return
    end

    respond_to do |format|
      if @payment.update(payment_params.except(:reimboursement_ids))
        # Aggiorna i rimborsi associati al pagamento
        update_payment_reimboursements(@payment, payment_params[:reimboursement_ids])
        format.html { redirect_to [ :admin, @payment ], notice: "Pagamento aggiornato con successo." }
        format.json { render :show, status: :ok, location: [ :admin, @payment ] }
      else
        @available_reimboursements = Reimboursement.payable.where(payment_id: nil).includes(:user, :bank_account)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payments/1 or /payments/1.json
  def destroy
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to admin_payments_path, status: :see_other, notice: "Pagamento eliminato con successo." }
      format.json { head :no_content }
    end
  end

  # GET /payments/1/export_flow
  def export_flow
    xml_content = @payment.generate_xml_flow

    send_data xml_content,
              filename: "flusso_pagamento_#{@payment.id}_#{Date.current.strftime('%Y%m%d')}.xml",
              type: "application/xml",
              disposition: "attachment"
  end

  # PATCH /payments/1/mark_as_paid
  def mark_as_paid
    begin
      @payment.mark_as_paid!(params[:payment_date]&.to_date || Date.current)
      redirect_to [ :admin, @payment ], notice: "Pagamento contrassegnato come eseguito."
    rescue => e
      redirect_to [ :admin, @payment ], alert: "Errore: #{e.message}"
    end
  end

  # PATCH /payments/1/revert_to_created
  def revert_to_created
    begin
      @payment.revert_to_created!
      redirect_to [ :admin, @payment ], notice: "Pagamento riportato allo stato 'Creato'."
    rescue => e
      redirect_to [ :admin, @payment ], alert: "Errore: #{e.message}"
    end
  end

  # PATCH /payments/1/retry
  def retry
    unless @payment.can_be_retried?
      redirect_to [ :admin, @payment ], alert: "Il pagamento non può essere ritentato."
      return
    end

    begin
      @payment.retry_processing!
      redirect_to [ :admin, @payment ], notice: "Processamento riavviato. Il pagamento verrà processato nuovamente."
    rescue => e
      redirect_to [ :admin, @payment ], alert: "Errore durante il retry: #{e.message}"
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

  # Aggiorna i rimborsi associati al pagamento
  def update_payment_reimboursements(payment, reimboursement_ids)
    # Rimuovi l'associazione dai rimborsi precedentemente associati
    # (li riporta allo stato approvato disponibile per altri pagamenti)
    payment.reimboursements.update_all(payment_id: nil, status: :approved)

    # Associa i nuovi rimborsi al pagamento se ce ne sono
    reimboursement_ids = Array(reimboursement_ids).reject(&:blank?)

    if reimboursement_ids.any?
      selected_reimboursements = Reimboursement.payable.where(id: reimboursement_ids)
      # I rimborsi associati a un pagamento "created" rimangono "approved"
      # Diventeranno "paid" solo quando il pagamento viene marcato come "paid"
      selected_reimboursements.update_all(payment_id: payment.id)
    end

    # Ricalcola sempre il totale del pagamento
    payment.reload # Ricarica per avere i nuovi rimborsi associati
    payment.recalculate_total!
  end
end
