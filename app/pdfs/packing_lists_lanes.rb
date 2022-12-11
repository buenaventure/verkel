class PackingListsLanes < CombinedPdf
  def initialize(box)
    @box = box
    super()
  end

  attr_reader :box

  def pdfs
    PackingLane.order(:name).map do |packing_lane|
      plb = PackingLaneBox.new(packing_lane:, box:)
      [PackingListLane.new(plb, filter: :warm), PackingListLane.new(plb, filter: :cold)]
    end.flatten
  end

  def filename
    "#{I18n.l(@box.datetime, format: :sortable).parameterize}-packstrassenlisten.pdf"
  end
end
