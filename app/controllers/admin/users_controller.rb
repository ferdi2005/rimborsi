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
      redirect_to admin_user_path(@user), notice: t("controllers.admin.users.update_success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.can_be_deleted?
      @user.destroy
      redirect_to admin_users_path, notice: t("controllers.admin.users.delete_success")
    else
      redirect_to admin_user_path(@user), alert: t("controllers.admin.users.delete_error")
    end
  end

  def deactivate
    @user.deactivate!
    redirect_to admin_user_path(@user), notice: t("controllers.admin.users.deactivate_success")
  rescue => e
    redirect_to admin_user_path(@user), alert: t("controllers.admin.users.deactivate_error", message: e.message)
  end

  def activate
    @user.activate!
    redirect_to admin_user_path(@user), notice: t("controllers.admin.users.activate_success")
  rescue => e
    redirect_to admin_user_path(@user), alert: t("controllers.admin.users.activate_error", message: e.message)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :surname, :email, :telephone, :fiscal_code, :active, :role_id)
  end
end
