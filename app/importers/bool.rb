class Bool
  BOOL = {
    'j' => true,
    'ja' => true,
    '1' => true,
    'n' => false,
    'nein' => false,
    '0' => false
  }.freeze

  def self.call(value)
    BOOL[value&.strip]
  end
end
