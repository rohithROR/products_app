require 'rails_helper'

RSpec.describe "Api::Products", type: :request do
  
  describe "GET /api/products" do
    it "GET /api/products" do
      get "/api/products"
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /api/products" do
    it "creates a new product" do
      post "/api/products", params: { product: { name: "Test Product", price: 100 } }
      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/products/:id" do
    context "when the product exists" do
      let!(:product) { create(:product, id: 10, name: 'SKU444', price: 4343) }

      it "returns a successful response" do
        get "/api/products/#{product.id}"
        expect(response).to have_http_status(:success)
      end

      it "returns the correct product" do
        get "/api/products/#{product.id}"
        expect(JSON.parse(response.body)["id"]).to eq(product.id)
      end
    end
  end

  describe "PATCH /api/products/:id" do
    let(:product) { create(:product, price: 100) } # Create a product with an initial price of 100

    context "when the product's price is updated to more than 50% of its previous price" do
      before do
        patch "/api/products/#{product.id}", params: { id: product.id, product: { price: 200 } }
        product.reload
      end

      it "pushes the product to the approval queue" do
        expect(product.approval_queue).to be_present
      end

      it "sets the product's status to 'pending'" do
        expect(product.status).to eq("pending")
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when the product's price is updated to less than or equal to 50% of its previous price" do
      before do
        patch "/api/products/#{product.id}", params: { id: product.id, product: { price: 50 } }
        product.reload
      end

      it "does not push the product to the approval queue" do
        expect(product.approval_queue).to be_nil
      end

      it "does not change the product's status" do
        expect(product.status).to_not eq("pending")
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "DELETE /api/products/:id" do
    let!(:product) { create(:product) }

    it "deletes the product from the database" do
      expect {
        delete "/api/products/#{product.id}"
      }.to change(Product, :count).by(-1)
    end

    it "returns a 204 No Content response" do
      delete "/api/products/#{product.id}"
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/products/search" do
    let!(:product1) { create(:product, name: "Product1", price: 50, created_at: 1.day.ago) }
    let!(:product2) { create(:product, name: "Product2", price: 100, created_at: 2.days.ago) }
    let!(:product3) { create(:product, name: "Product3", price: 150, created_at: 3.days.ago) }

    it "returns products based on search criteria" do
      get '/api/products/search', params: { productName: "Product", minPrice: 50, maxPrice: 150, minPostedDate: 2.days.ago, maxPostedDate: 1.day.ago }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).count).to eq(2)
      expect(JSON.parse(response.body).map { |p| p["name"] }).to contain_exactly("Product1", "Product2")
    end

    it "returns all products if no search parameters are provided" do
      get '/api/products/search'
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).count).to eq(3)
    end
  end

  describe "GET /api/products/approval-queue" do
    it "GET /api/products/approval-queue" do
      get "/api/products/approval-queue"
      expect(response).to have_http_status(200)
    end
  end

  describe "PUT /api/products/approval-queue/:id/approve" do
    let!(:product) { create(:product, status: 'pending') }
    let!(:approval_queue) { create(:approval_queue, product_id: product.id) }

    it "approves the product and removes it from the approval queue" do
      put "/api/products/approval-queue/#{approval_queue.id}/approve"
      
      product.reload
      expect(product.status).to eq('active')
      expect(ApprovalQueue.exists?(approval_queue.id)).to be_falsey
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["message"]).to eq('Product approved successfully.')
    end
  end

  describe "PUT /api/products/approval-queue/:id/reject" do
    let!(:product) { create(:product, status: 'pending') }
    let!(:approval_queue) { create(:approval_queue, product_id: product.id) }

    it "reject the product and removes it from the approval queue" do
      put "/api/products/approval-queue/#{approval_queue.id}/reject"
      
      product.reload
      expect(product.status).to eq('pending')
      expect(ApprovalQueue.exists?(approval_queue.id)).to be_falsey
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["message"]).to eq('Product rejected successfully.')
    end
  end
end
