class Admin::UsersController < ApplicationController
  before_action :ensure_admin
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :deactivate, :activate ]

  def index
    @users = User.includes(:role).order(:name, :surname)
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "Utente aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.can_be_deleted?
      @user.destroy
      redirect_to admin_users_path, notice: "Utente eliminato con successo."
    else
      redirect_to admin_user_path(@user), alert: "Impossibile eliminare l'utente: ha dei rimborsi associati."
    end
  end

  def deactivate
    @user.deactivate!
    redirect_to admin_user_path(@user), notice: "Utente disattivato con successo."
  rescue => e
    redirect_to admin_user_path(@user), alert: "Errore nella disattivazione: #{e.message}"
  end

  def activate
    @user.activate!
    redirect_to admin_user_path(@user), notice: "Utente attivato con successo."
  rescue => e
    redirect_to admin_user_path(@user), alert: "Errore nell'attivazione: #{e.message}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :surname, :email, :telephone, :active, :role_id)
  end
end
