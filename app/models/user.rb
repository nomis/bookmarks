class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  has_paper_trail skip: [
    :created_at, :updated_at,

    ## Recoverable
    :reset_password_token, :reset_password_sent_at,

    ## Rememberable
    :remember_created_at,

    ## Trackable
    :sign_in_count,
    :current_sign_in_at,
    :last_sign_in_at,
    :current_sign_in_ip,
    :last_sign_in_ip,

    ## Confirmable
    :confirmation_token,
    :confirmed_at,
    :confirmation_sent_at,
    #:unconfirmed_email,

    ## Lockable
    :failed_attempts,
    :unlock_token,
    :locked_at,
  ]

  attr_writer :login

  def login
    @login || self.username || self.email
  end

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /^[a-zA-Z0-9_-]*$/, :multiline => true

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
end
