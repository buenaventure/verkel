module ImportsHelper
  def import_row_status(row)
    @row_keys ||= @report.attributes.keys.filter do |k|
      k.ends_with? '_rows'
    end
    @row_keys.find do |k|
      @report.send(k).include? row
    end.to_s.delete_suffix('_rows')
  end
end
