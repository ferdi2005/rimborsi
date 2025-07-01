class PaypalAccountsController < ApplicationController
  before_action :set_paypal_account, only: %i[ show edit update destroy ]

  # GET /paypal_accounts or /paypal_accounts.json
  def index
    if current_user.admin?
      @paypal_accounts = PaypalAccount.includes(:user).order("users.name", "users.surname")
    else
      @paypal_accounts = current_user.paypal_accounts
    end
  end

  # GET /paypal_accounts/1 or /paypal_accounts/1.json
  def show
  end

  # GET /paypal_accounts/new
  def new
    @paypal_account = PaypalAccount.new
  end

  # GET /paypal_accounts/1/edit
  def edit
  end

  # POST /paypal_accounts or /paypal_accounts.json
  def create
    if current_user.admin? && params[:paypal_account][:user_id].present?
      @paypal_account = PaypalAccount.new(paypal_account_params)
    else
      @paypal_account = current_user.paypal_accounts.build(paypal_account_params)
    end

    respond_to do |format|
      if @paypal_account.save
        format.html { redirect_to @paypal_account, notice: "Account PayPal creato con successo." }
        format.json { render :show, status: :created, location: @paypal_account }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @paypal_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /paypal_accounts/1 or /paypal_accounts/1.json
  def update
    respond_to do |format|
      if @paypal_account.update(paypal_account_params)
        format.html { redirect_to @paypal_account, notice: "Account PayPal aggiornato con successo." }
        format.json { render :show, status: :ok, location: @paypal_account }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @paypal_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /paypal_accounts/1 or /paypal_accounts/1.json
  def destroy
    @paypal_account.destroy!

    respond_to do |format|
      format.html { redirect_to paypal_accounts_path, status: :see_other, notice: "Account PayPal eliminato con successo." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_paypal_account
      if current_user.admin?
        @paypal_account = PaypalAccount.find(params[:id])
      else
        @paypal_account = current_user.paypal_accounts.find(params[:id])
      end
    end

    # Only allow a list of trusted parameters through.
    def paypal_account_params
      if current_user.admin?
        params.require(:paypal_account).permit(:email, :default, :user_id)
      else
        params.require(:paypal_account).permit(:email, :default)
      end
    end
end
