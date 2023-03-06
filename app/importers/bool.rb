module Bool
  BOOL = {
    'j' => true,
    'ja' => true,
    '1' => true,
    'n' => false,
    'nein' => false,
    '0' => false
  }.freeze

  def call(value)
    BOOL[value&.strip]
  end
end
