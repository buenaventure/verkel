# frozen_string_literal: true

# Bearer token that signs its user in for JSON requests. Only a SHA-256 digest is
# stored; the plain token is readable once, right after creation.
class ApiToken < ApplicationRecord
  SCOPES = %w[read write].freeze
  PREFIX = 'verkel_'
  LAST_USED_PRECISION = 1.minute

  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :scopes, presence: true
  validate :scopes_known

  before_validation :generate_token, on: :create

  scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  attr_reader :plain_token

  def self.authenticate(plain_token)
    return if plain_token.blank?

    active.includes(:user).find_by(token_digest: digest(plain_token))
  end

  def self.digest(plain_token)
    OpenSSL::Digest::SHA256.hexdigest(plain_token)
  end

  def write?
    scopes.include?('write')
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at.future?)
  end

  def revoke!
    update!(revoked_at: Time.current) if revoked_at.nil?
  end

  # Written at most once a minute so that busy clients don't turn every read into a write.
  def touch_last_used
    return if last_used_at && last_used_at > LAST_USED_PRECISION.ago

    update_column(:last_used_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def to_s
    name
  end

  private

  def generate_token
    return if token_digest.present?

    @plain_token = "#{PREFIX}#{SecureRandom.base58(32)}"
    self.token_digest = self.class.digest(@plain_token)
  end

  def scopes_known
    unknown = Array(scopes) - SCOPES
    errors.add(:scopes, :inclusion) if unknown.any?
  end
end
