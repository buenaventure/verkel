class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable
  # :registerable, :recoverable, :validatable
  devise :database_authenticatable, :rememberable, :lockable, :trackable
  enum role: {read_only: 0, laga: 1, office: 2, admin: 3}

  def to_s
    email
  end
end
