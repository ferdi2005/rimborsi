class ReimboursementsController < ApplicationController
  before_action :set_reimboursement, only: %i[ show edit update destroy download_pdf approve_expenses approve_expense deny_expense approve_reimboursement submit ]

  # GET /reimboursements or /reimboursements.json
  def index
    # Definisci gli stati di default
    default_statuses = current_user.admin? ? [ "created", "in_process", "waiting" ] : [ "draft", "created", "in_process", "waiting" ]

    # Ottieni i parametri di filtro
    @filter_statuses = params[:statuses].present? ? params[:statuses].reject(&:blank?) : default_statuses
    @filter_user_id = params[:user_id].presence

    # Base query
    if current_user.admin?
      @reimboursements = Reimboursement.all
      @users = User.joins(:reimboursements).distinct.order(:name, :surname)
    else
      @reimboursements = current_user.reimboursements
      @users = [ current_user ] # Solo l'utente corrente
    end

    # Applica filtri
    if @filter_statuses.present?
      @reimboursements = @reimboursements.where(status: @filter_statuses)
    end

    if @filter_user_id.present? && current_user.admin?
      @reimboursements = @reimboursements.where(user_id: @filter_user_id)
    end

    @reimboursements = @reimboursements.includes(:user, :bank_account, :expenses).order(created_at: :desc)
  end

  # GET /reimboursements/1 or /reimboursements/1.json
  def show
  end

  # GET /reimboursements/new
  def new
    @reimboursement = Reimboursement.new
    @reimboursement.expenses.build # Crea una spesa vuota per il form
    @funds = Fund.active.order(:name)
  end

  # GET /reimboursements/1/edit
  def edit
    unless @reimboursement.can_be_edited_by?(current_user)
      redirect_to @reimboursement, alert: t("controllers.reimboursements.cannot_modify")
      nil
    end
    @funds = Fund.active.order(:name)
  end

  # POST /reimboursements or /reimboursements.json
  def create
    saving_as_draft = params[:save_draft].present?

    if current_user.admin?
      target_status = if params[:reimboursement][:status].present? && !saving_as_draft
                        params[:reimboursement][:status]
                      elsif saving_as_draft
                        "draft"
                      else
                        "created"
                      end
      @reimboursement = Reimboursement.new(reimboursement_params.except(:initial_note).merge(status: target_status))
    else
      target_status = saving_as_draft ? "draft" : "created"
      @reimboursement = current_user.reimboursements.build(reimboursement_params.except(:user_id, :initial_note).merge(status: target_status))
    end

    respond_to do |format|
      if saving_as_draft
        if @reimboursement.save
          create_initial_note_if_present
          format.html { redirect_to @reimboursement, notice: t("controllers.reimboursements.create.draft_success") }
          format.json { render :show, status: :created, location: @reimboursement }
        else
          @funds = Fund.active.order(:name)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
        end
      else
        # Tentativo di invio
        if @reimboursement.valid? && @reimboursement.save
          create_initial_note_if_present
          format.html { redirect_to @reimboursement, notice: t("controllers.reimboursements.create.success") }
          format.json { render :show, status: :created, location: @reimboursement }
        else
          # Se la validazione fallisce, salviamo come bozza per non perdere dati e allegati
          validation_errors = @reimboursement.errors.dup
          @reimboursement.status = "draft"
          if @reimboursement.save
            create_initial_note_if_present
            validation_errors.each do |error|
              @reimboursement.errors.import(error)
            end
            flash.now[:alert] = t("controllers.reimboursements.saved_as_draft_due_to_errors")
            @funds = Fund.active.order(:name)
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
          else
            @funds = Fund.active.order(:name)
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
          end
        end
      end
    end
  end

  # PATCH/PUT /reimboursements/1 or /reimboursements/1.json
  def update
    unless @reimboursement.can_be_edited_by?(current_user)
      respond_to do |format|
        format.html { redirect_to @reimboursement, alert: t("controllers.reimboursements.cannot_modify") }
        format.json { render json: { error: "Non autorizzato" }, status: :forbidden }
      end
      return
    end

    update_attrs = reimboursement_params.except(:initial_note)

    if @reimboursement.status_draft?
      if params[:submit_reimbursement].present?
        # Tentativo di invio da bozza a creato
        @reimboursement.assign_attributes(update_attrs.merge(status: "created"))
        if @reimboursement.valid?
          @reimboursement.save
          create_initial_note_if_present
          respond_to do |format|
            format.html { redirect_to @reimboursement, notice: t("controllers.reimboursements.submitted_success") }
            format.json { render :show, status: :ok, location: @reimboursement }
          end
          return
        else
          # Non valido per l'invio: salva le modifiche come bozza e mostra errori
          validation_errors = @reimboursement.errors.dup
          @reimboursement.status = "draft"
          @reimboursement.save
          validation_errors.each do |error|
            @reimboursement.errors.import(error)
          end
          flash.now[:alert] = t("controllers.reimboursements.draft_cannot_submit_due_to_errors")
          @funds = Fund.active.order(:name)
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
          end
          return
        end
      elsif params[:save_draft].present?
        update_attrs[:status] = "draft" unless current_user.admin? && params[:reimboursement][:status].present?
      end
    end

    old_status = @reimboursement.status

    respond_to do |format|
      if @reimboursement.update(update_attrs)
        create_initial_note_if_present

        notice_msg = if @reimboursement.status_draft?
                       t("controllers.reimboursements.draft_update_success")
                     else
                       t("controllers.reimboursements.update_success")
                     end

        format.html { redirect_to @reimboursement, notice: notice_msg }
        format.json { render :show, status: :ok, location: @reimboursement }
      else
        @funds = Fund.active.order(:name)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reimboursement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /reimboursements/1/submit
  def submit
    redirect_to root_path and return unless @reimboursement

    unless @reimboursement.user == current_user || current_user.admin?
      redirect_to @reimboursement, alert: t("controllers.reimboursements.cannot_modify")
      return
    end

    unless @reimboursement.status_draft?
      redirect_to @reimboursement, alert: t("controllers.reimboursements.cannot_submit")
      return
    end

    @reimboursement.status = "created"
    if @reimboursement.valid? && @reimboursement.save
      redirect_to @reimboursement, notice: t("controllers.reimboursements.submitted_success")
    else
      validation_errors = @reimboursement.errors.full_messages.to_sentence
      @reimboursement.status = "draft"
      redirect_to edit_reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.cannot_submit_with_errors", errors: validation_errors)
    end
  end

  # DELETE /reimboursements/1 or /reimboursements/1.json
  def destroy
    unless @reimboursement.status_created? || @reimboursement.status_draft?
      redirect_to reimboursements_path, alert: t("controllers.reimboursements.cannot_delete")
      return
    end

    @reimboursement.destroy!

    respond_to do |format|
      format.html { redirect_to reimboursements_path, status: :see_other, notice: t("controllers.reimboursements.delete_success") }
      format.json { head :no_content }
    end
  end

  # GET /reimboursements/1/approve_expenses
  def approve_expenses
    redirect_to root_path and return unless @reimboursement
    return admin_required unless current_user.admin?

    if @reimboursement.status_draft?
      redirect_to reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.draft_cannot_approve_expenses")
      return
    end

    @current_expense_index = params[:expense_index]&.to_i || 0
    # Include sia spese normali che auto, ordinate per data
    @expenses = @reimboursement.expenses.order(:date)

    if @current_expense_index >= @expenses.count
      redirect_to reimboursement_path(@reimboursement), notice: t("controllers.reimboursements.all_expenses_reviewed")
      return
    end

    @current_expense = @expenses[@current_expense_index]
    @total_expenses = @expenses.count
  end

  # PATCH /reimboursements/1/approve_expense
  def approve_expense
    redirect_to root_path and return unless @reimboursement
    return admin_required unless current_user.admin?

    if @reimboursement.status_draft?
      redirect_to reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.draft_cannot_approve_expenses")
      return
    end

    expense = @reimboursement.expenses.find(params[:expense_id])

    # Aggiorna il requested_amount se fornito
    if params[:requested_amount].present?
      expense.update!(requested_amount: params[:requested_amount])
    end

    expense.update!(status: "approved")

    redirect_to approve_expenses_reimboursement_path(@reimboursement, expense_index: params[:next_index]),
                notice: t("controllers.reimboursements.expense_approved")
  end

  # PATCH /reimboursements/1/deny_expense
  def deny_expense
    redirect_to root_path and return unless @reimboursement
    return admin_required unless current_user.admin?

    if @reimboursement.status_draft?
      redirect_to reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.draft_cannot_approve_expenses")
      return
    end

    expense = @reimboursement.expenses.find(params[:expense_id])

    # Aggiorna il requested_amount se fornito
    if params[:requested_amount].present?
      expense.update!(requested_amount: params[:requested_amount])
    end

    expense.update!(status: "denied")

    # Crea una nota se fornita
    if params[:note_content].present?
      note = @reimboursement.notes.build(
        text: params[:note_content],
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
                notice: t("controllers.reimboursements.expense_denied")
  end

  # PATCH /reimboursements/1/approve_reimboursement
  def approve_reimboursement
    redirect_to root_path and return unless @reimboursement
    return admin_required unless current_user.admin?

    if @reimboursement.status_draft?
      redirect_to reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.draft_cannot_approve_expenses")
      return
    end

    if @reimboursement.can_be_approved?
      @reimboursement.update!(status: "approved")

      # Crea una nota automatica
      @reimboursement.notes.create!(
        text: t("controllers.reimboursements.auto_note_approved"),
        user: current_user,
        status_change: "approved"
      )

      redirect_to reimboursement_path(@reimboursement), notice: t("controllers.reimboursements.reimbursement_approved")
    else
      redirect_to reimboursement_path(@reimboursement), alert: t("controllers.reimboursements.pending_expenses_exist")
    end
  end

  # GET /reimboursements/1/download_pdf
  def download_pdf
    begin
      pdf_content = @reimboursement.generate_pdf

      send_data pdf_content,
                filename: "rimborso_#{@reimboursement.id}_#{Date.current.strftime('%Y%m%d')}.pdf",
                type: "application/pdf",
                disposition: "attachment",
                content_length: pdf_content.bytesize
    rescue => e
      Rails.logger.error "Error generating PDF for reimboursement #{@reimboursement.id}: #{e.message}"
      redirect_to @reimboursement, alert: t("controllers.reimboursements.pdf_error")
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
      permitted_params = [ :bank_account_id, :initial_note,
                         :role, :role_other, :project, :fund_id,
                         expenses_attributes: [
                           :id, :amount, :requested_amount, :purpose, :date, :car, :attachment, :_destroy,
                           :calculation_date, :departure, :arrival, :distance, :return_trip,
                           :vehicle_id, :quota_capitale, :carburante, :pneumatici, :manutenzione, :project
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

    def create_initial_note_if_present
      if params[:reimboursement] && params[:reimboursement][:initial_note].present?
        @reimboursement.notes.create!(
          text: params[:reimboursement][:initial_note],
          user: current_user,
          status_change: false
        )
      end
    end
end
