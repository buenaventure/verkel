module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID
        class Timestamp
          def infinity(negative: _negative); end # return nil as infinity
        end
      end
    end
  end
end

class NilClass
  def infinite?
    true
  end
end
