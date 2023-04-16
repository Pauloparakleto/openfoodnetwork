class Invoice::VariantSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :options_text
  has_one :product, serializer: Invoice::ProductSerializer
end
