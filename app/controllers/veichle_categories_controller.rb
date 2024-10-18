class VeichleCategoriesController < ApplicationController
  before_action :set_veichle_category, only: %i[ show edit update destroy ]

  # GET /veichle_categories or /veichle_categories.json
  def index
    @veichle_categories = VeichleCategory.all
  end

  # GET /veichle_categories/1 or /veichle_categories/1.json
  def show
  end

  # GET /veichle_categories/new
  def new
    @veichle_category = VeichleCategory.new
  end

  # GET /veichle_categories/1/edit
  def edit
  end

  # POST /veichle_categories or /veichle_categories.json
  def create
    @veichle_category = VeichleCategory.new(veichle_category_params)

    respond_to do |format|
      if @veichle_category.save
        format.html { redirect_to @veichle_category, notice: "Veichle category was successfully created." }
        format.json { render :show, status: :created, location: @veichle_category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @veichle_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /veichle_categories/1 or /veichle_categories/1.json
  def update
    respond_to do |format|
      if @veichle_category.update(veichle_category_params)
        format.html { redirect_to @veichle_category, notice: "Veichle category was successfully updated." }
        format.json { render :show, status: :ok, location: @veichle_category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @veichle_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /veichle_categories/1 or /veichle_categories/1.json
  def destroy
    @veichle_category.destroy!

    respond_to do |format|
      format.html { redirect_to veichle_categories_path, status: :see_other, notice: "Veichle category was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_veichle_category
      @veichle_category = VeichleCategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def veichle_category_params
      params.require(:veichle_category).permit(:label)
    end
end
