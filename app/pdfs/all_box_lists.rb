class AllBoxLists < CombinedPdf
  def initialize(box)
    @box = box
    super()
  end

  attr_reader :box

  def pdfs
    [
      PackingListsGroups.new(@box),
      PackingListsArticles.new(@box, filter: :warm),
      PackingListsArticles.new(@box, filter: :cold),
      PackingListsMissingIngredients.new(@box)
    ]
  end

  def filename
    "#{I18n.l(@box.datetime, format: :sortable).parameterize}-alle_listen.pdf"
  end
end
