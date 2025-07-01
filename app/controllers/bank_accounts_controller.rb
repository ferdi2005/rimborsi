class BankAccountsController < ApplicationController
  before_action :set_bank_account, only: %i[ show edit update destroy ]

  # GET /bank_accounts or /bank_accounts.json
  def index
    if current_user.admin?
      @bank_accounts = BankAccount.includes(:user).order("users.name", "users.surname")
    else
      @bank_accounts = current_user.bank_accounts
    end
  end

  # GET /bank_accounts/1 or /bank_accounts/1.json
  def show
  end

  # GET /bank_accounts/new
  def new
    @bank_account = BankAccount.new
  end

  # GET /bank_accounts/1/edit
  def edit
  end

  # POST /bank_accounts or /bank_accounts.json
  def create
    if current_user.admin? && params[:bank_account][:user_id].present?
      @bank_account = BankAccount.new(bank_account_params)
    else
      @bank_account = current_user.bank_accounts.build(bank_account_params)
    end

    respond_to do |format|
      if @bank_account.save
        format.html { redirect_to @bank_account, notice: "Conto bancario creato con successo." }
        format.json { render :show, status: :created, location: @bank_account }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @bank_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bank_accounts/1 or /bank_accounts/1.json
  def update
    respond_to do |format|
      if @bank_account.update(bank_account_params)
        format.html { redirect_to @bank_account, notice: "Conto bancario aggiornato con successo." }
        format.json { render :show, status: :ok, location: @bank_account }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bank_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bank_accounts/1 or /bank_accounts/1.json
  def destroy
    @bank_account.destroy!

    respond_to do |format|
      format.html { redirect_to bank_accounts_path, status: :see_other, notice: "Conto bancario eliminato con successo." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bank_account
      if current_user.admin?
        @bank_account = BankAccount.find(params[:id])
      else
        @bank_account = current_user.bank_accounts.find(params[:id])
      end
    end

    # Only allow a list of trusted parameters through.
    def bank_account_params
      if current_user.admin?
        params.require(:bank_account).permit(:iban, :owner, :address, :cap, :town, :fiscal_code, :default, :user_id)
      else
        params.require(:bank_account).permit(:iban, :owner, :address, :cap, :town, :fiscal_code, :default)
      end
    end
end
