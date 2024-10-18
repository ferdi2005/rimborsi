class PaypalAccountsController < ApplicationController
  before_action :set_paypal_account, only: %i[ show edit update destroy ]

  # GET /paypal_accounts or /paypal_accounts.json
  def index
    @paypal_accounts = PaypalAccount.all
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
    @paypal_account = PaypalAccount.new(paypal_account_params)

    respond_to do |format|
      if @paypal_account.save
        format.html { redirect_to @paypal_account, notice: "Paypal account was successfully created." }
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
        format.html { redirect_to @paypal_account, notice: "Paypal account was successfully updated." }
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
      format.html { redirect_to paypal_accounts_path, status: :see_other, notice: "Paypal account was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_paypal_account
      @paypal_account = PaypalAccount.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def paypal_account_params
      params.require(:paypal_account).permit(:email, :user_id, :default)
    end
end
