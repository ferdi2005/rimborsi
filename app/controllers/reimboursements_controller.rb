class ReimboursementsController < ApplicationController
  before_action :set_reimboursement, only: %i[ show edit update destroy download_pdf ]

  # GET /reimboursements or /reimboursements.json
  def index
    if current_user.admin?
      @reimboursements = Reimboursement.order(created_at: :asc)
    else
      @reimboursements = current_user.reimboursements.order(created_at: :asc)
    end
  end

  # GET /reimboursements/1 or /reimboursements/1.json
  def show
  end

  # GET /reimboursements/new
  def new
    @reimboursement = Reimboursement.new
    @reimboursement.expenses.build # Crea una spesa vuota per il form
    @projects = Project.active.order(:name)
  end

  # GET /reimboursements/1/edit
  def edit
    unless @reimboursement.can_be_edited_by?(current_user)
      redirect_to @reimboursement, alert: "Non puoi modificare questo rimborso. I rimborsi possono essere modificati solo se sono in stato 'Creato' o 'In Attesa', oppure se sei un amministratore."
      nil
    end
    @projects = Project.active.order(:name)
  end

  # POST /reimboursements or /reimboursements.json
  def create
    if current_user.admin?
      # Gli admin possono creare rimborsi per qualsiasi utente
      @reimboursement = Reimboursement.new(reimboursement_params.except(:initial_note))
    else
      # Gli utenti normali possono creare solo rimborsi per se stessi
      @reimboursement = current_user.reimboursements.build(reimboursement_params.except(:user_id, :initial_note))
    end

    respond_to do |format|
      if @reimboursement.save
        # Crea la nota iniziale se presente
        if params[:reimboursement][:initial_note].present?
          @reimboursement.notes.create!(
            content: params[:reimboursement][:initial_note],
            user: current_user,
            status_change: false
          )
        end

        format.html { redirect_to @reimboursement, notice: "🎉 Rimborso creato con successo! Riceverai aggiornamenti via email per ogni cambio di stato." }
        format.json { render :show, status: :created, location: @reimboursement }
      else
        @projects = Project.active.order(:name)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reimboursements/1 or /reimboursements/1.json
  def update
    unless @reimboursement.can_be_edited_by?(current_user)
      respond_to do |format|
        format.html { redirect_to @reimboursement, alert: "Non puoi modificare questo rimborso. I rimborsi possono essere modificati solo se sono in stato 'Creato' o 'In Attesa', oppure se sei un amministratore." }
        format.json { render json: { error: "Non autorizzato" }, status: :forbidden }
      end
      return
    end

    old_status = @reimboursement.status

    respond_to do |format|
      if @reimboursement.update(reimboursement_params.except(:initial_note))
        # Crea una nuova nota se è presente il campo initial_note
        if params[:reimboursement][:initial_note].present?
          @reimboursement.notes.create!(
            content: params[:reimboursement][:initial_note],
            user: current_user,
            status_change: false
          )
        end

        # Se lo status è cambiato, invia notifica email
        if old_status != @reimboursement.status
          ReimboursementMailer.status_changed(@reimboursement).deliver_later
        end

        format.html { redirect_to @reimboursement, notice: "Rimborso aggiornato con successo." }
        format.json { render :show, status: :ok, location: @reimboursement }
      else
        @projects = Project.active.order(:name)
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

  # GET /reimboursements/1/approve_expenses
  def approve_expenses
    @reimboursement = Reimboursement.find(params[:id])
    redirect_to root_path and return unless @reimboursement

    return admin_required unless current_user.admin?

    @current_expense_index = params[:expense_index]&.to_i || 0
    # Include sia spese normali che auto, ordinate per data
    @expenses = @reimboursement.expenses.order(:date)

    if @current_expense_index >= @expenses.count
      redirect_to reimboursement_path(@reimboursement), notice: "Tutti i giustificativi sono stati revisionati."
      return
    end

    @current_expense = @expenses[@current_expense_index]
    @total_expenses = @expenses.count
  end

  # PATCH /reimboursements/1/approve_expense
  def approve_expense
    return admin_required unless current_user.admin?

    expense = @reimboursement.expenses.find(params[:expense_id])
    expense.update!(status: "approved")

    redirect_to approve_expenses_reimboursement_path(@reimboursement, expense_index: params[:next_index]),
                notice: "Giustificativo approvato."
  end

  # PATCH /reimboursements/1/deny_expense
  def deny_expense
    return admin_required unless current_user.admin?

    expense = @reimboursement.expenses.find(params[:expense_id])
    expense.update!(status: "denied")

    # Crea una nota se fornita
    if params[:note_content].present?
      note = @reimboursement.notes.build(
        content: params[:note_content],
        user: current_user,
        status_change: params[:reimboursement_status] || "waiting"
      )

      if note.save
        # Aggiorna lo status del rimborso se specificato
        if params[:reimboursement_status].present?
          @reimboursement.update!(status: params[:reimboursement_status])
        end
      end
    end

    redirect_to approve_expenses_reimboursement_path(@reimboursement, expense_index: params[:next_index]),
                notice: "Giustificativo rifiutato."
  end

  # PATCH /reimboursements/1/approve_reimboursement
  def approve_reimboursement
    return admin_required unless current_user.admin?

    if @reimboursement.can_be_approved?
      @reimboursement.update!(status: "approved")

      # Crea una nota automatica
      @reimboursement.notes.create!(
        content: "Rimborso approvato.",
        user: current_user,
        status_change: "approved"
      )

      redirect_to reimboursement_path(@reimboursement), notice: "Rimborso approvato con successo!"
    else
      redirect_to reimboursement_path(@reimboursement), alert: "Non è possibile approvare il rimborso: ci sono ancora giustificativi in attesa di approvazione."
    end
  end

  # GET /reimboursements/1/download_pdf
  def download_pdf
    begin
      pdf_content = @reimboursement.generate_pdf

      send_data pdf_content,
                filename: "rimborso_#{@reimboursement.id}_#{Date.current.strftime('%Y%m%d')}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    rescue => e
      Rails.logger.error "Error generating PDF for reimboursement #{@reimboursement.id}: #{e.message}"
      redirect_to @reimboursement, alert: "Errore nella generazione del PDF. Riprova più tardi."
    end
  end

  private
    def set_reimboursement
      if current_user.admin?
        @reimboursement = Reimboursement.find(params[:id])
      else
        @reimboursement = current_user.reimboursements.find(params[:id])
      end
    end

    def reimboursement_params
      permitted_params = [ :bank_account_id, :paypal_account_id, :initial_note,
                         expenses_attributes: [
                           :id, :amount, :purpose, :date, :car, :attachment, :_destroy,
                           :calculation_date, :departure, :arrival, :distance, :return_trip,
                           :vehicle_id, :quota_capitale, :carburante, :pneumatici, :manutenzione,
                           :project_id
                         ] ]

      # Se è admin, può anche modificare user_id e status
      if current_user.admin?
        permitted_params << :user_id
        permitted_params << :status
        # Trova l'hash expenses_attributes e aggiungi :status
        expenses_hash = permitted_params.find { |param| param.is_a?(Hash) && param.key?(:expenses_attributes) }
        expenses_hash[:expenses_attributes] << :status if expenses_hash
      end

      params.require(:reimboursement).permit(permitted_params)
    end
end
