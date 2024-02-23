class Api::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :destroy]
  before_action :set_approval_queue, only: [:approve, :reject]

  # GET /api/products
  def index
    @products = Product.active.order(created_at: :desc)
    render json: @products
  end

  # GET /api/products/1
  def show
    render json: @product
  end

  # POST /api/products
  def create
    @product = Product.new(product_params)
    @product.status = 'active'
    if @product.price > 10000
      render json: { error: "Price cannot exceed $10,000" }, status: :unprocessable_entity and return 
    elsif @product.price > 5000
    	@product.status = 'pending'
      @product.build_approval_queue
    end

    if @product.save
      render json: @product, status: :created
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/products/1
  def update
    # Save previous price for comparison
    previous_price = @product.price

    if @product.update(product_params)
      # Check if the new price is more than 50% of the previous price
      if @product.price > (previous_price * 1.5)
        # If so, push the product to the approval queue
        @product.approval_queue ||= ApprovalQueue.new
        @product.approval_queue.save!
        @product.update(status: "pending")
      end
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/products/1
  def destroy
    @product.destroy
    head :no_content
  end

  # GET /api/products/search
  def search
    @products = Product.all

    if params[:productName].present?
      @products = @products.where("name LIKE ?", "%#{params[:productName]}%")
    end
    if params[:minPrice].present?
      @products = @products.where("price >= ?", params[:minPrice])
    end

    if params[:maxPrice].present?
      @products = @products.where("price <= ?", params[:maxPrice])
    end
    if params[:minPostedDate].present?
      @products = @products.where("Date(created_at) >= ?", params[:minPostedDate].to_date)
    end

    if params[:maxPostedDate].present?
      @products = @products.where("Date(created_at) <= ?", params[:maxPostedDate].to_date)
    end

    render json: @products
  end

  def approval_queue
  	@queues = ApprovalQueue.order(created_at: :desc)
    render json: @queues
  end

  def approve
    @product = @approval_queue.product
    # Update product state and remove from approval queue
    if @product.update(status: 'active') && @approval_queue.destroy
      render json: { message: 'Product approved successfully.'}
    else
      render json: { error: 'Failed to approve product' }, status: :unprocessable_entity
    end
  end

  def reject
    # Remove product from approval queue
    if @approval_queue.destroy
      render json: { message: 'Product rejected successfully.' }
    else
      render json: { error: 'Failed to reject product' }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_approval_queue
    begin
      @approval_queue = ApprovalQueue.find(params[:approvalId])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: 'Approval queue not found' }, status: :not_found
    end
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.require(:product).permit(:name, :description, :price)
  end
end
