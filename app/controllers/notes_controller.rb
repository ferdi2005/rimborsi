class NotesController < ApplicationController
  before_action :set_reimboursement
  before_action :set_note, only: [ :destroy ]
  before_action :check_permissions

  def create
    @note = @reimboursement.notes.build(note_params)
    @note.user = current_user

    # Se c'è un cambio di stato e l'utente è admin, aggiorna anche il rimborso
    if @note.status_change.present? && current_user.admin?
      @reimboursement.update(status: @note.status_change)
    end

    respond_to do |format|
      if @note.save
        format.html { redirect_to @reimboursement, notice: "Nota aggiunta con successo." }
        format.json { render json: { status: "success", message: "Nota aggiunta con successo." } }
      else
        format.html { redirect_to @reimboursement, alert: "Errore nel salvare la nota." }
        format.json { render json: { status: "error", errors: @note.errors.full_messages } }
      end
    end
  end

  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to @reimboursement, notice: "Nota eliminata con successo." }
      format.json { render json: { status: "success", message: "Nota eliminata con successo." } }
    end
  end

  private

  def set_reimboursement
    @reimboursement = if current_user.admin?
                       Reimboursement.find(params[:reimboursement_id])
    else
                       current_user.reimboursements.find(params[:reimboursement_id])
    end
  end

  def set_note
    @note = @reimboursement.notes.find(params[:id])
  end

  def check_permissions
    return if current_user.admin?
    return if @reimboursement.user_id == current_user.id

    redirect_to reimboursements_path, alert: "Non hai i permessi per accedere a questo rimborso."
  end

  def note_params
    permitted_params = [ :text ]
    permitted_params << :status_change if current_user.admin?
    params.require(:note).permit(permitted_params)
  end
end
