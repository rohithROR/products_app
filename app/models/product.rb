class Product < ApplicationRecord

	has_one :approval_queue

	scope :active, -> { where(status: :active) }

	validates_uniqueness_of :name, message: 'Product has already been taken.'
	validates_inclusion_of :price, :in => 0..10000, message: 'Product price cannot exceed $10,000.'

	validate :validate_product, if: :specific_fields_changed?

	def validate_product
		if approval_queue.present?
			errors.add(:base, 'Product sent for an Approval, please wait for sometime.')
			return false
		end
	end

	def specific_fields_changed?
		changed.include?('name') || changed.include?('price') 
	end
end
