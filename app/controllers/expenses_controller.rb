class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[  update destroy download_invoice_pdf ]

  # POST /expenses or /expenses.json
  def create
    @expense = current_user.expenses.build(expense_params)

    respond_to do |format|
      if @expense.save
        format.html { redirect_to @expense, notice: "Expense was successfully created." }
        format.json { render :show, status: :created, location: @expense }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenses/1 or /expenses/1.json
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html { redirect_to @expense, notice: "Expense was successfully updated." }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1 or /expenses/1.json
  def destroy
    @expense.destroy!

    respond_to do |format|
      format.html { redirect_to expenses_path, status: :see_other, notice: "Expense was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /expenses/1/download_invoice_pdf
  def download_invoice_pdf
    if @expense.pdf_attachment.attached?
      send_data @expense.pdf_attachment.download,
                filename: @expense.pdf_attachment.filename.to_s,
                type: "application/pdf",
                disposition: "attachment"
    else
      redirect_back(fallback_location: @expense, alert: "PDF della fattura non disponibile.")
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_expense
      if current_user.admin?
        @expense = Expense.find(params[:id])
      else
        @expense = current_user.expenses.find(params[:id])
      end
    end
    # Only allow a list of trusted parameters through.
    def expense_params
      params.require(:expense).permit(:reimboursement_id, :purpose, :project, :date, :amount, :car, :calculation_date, :departure, :arrival, :distance, :return_trip, :vehicle_category_id, :brand, :model, :fuel_id, :quota_capitale, :carburante, :pneumatici, :manutenzione, :fund_id, :attachment)
    end
end
