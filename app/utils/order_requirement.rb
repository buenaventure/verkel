OrderRequirement = Struct.new(:box_id, :quantity, :stock, :ordered, keyword_init: true) do
  def total
    quantity + stock + ordered
  end
end
