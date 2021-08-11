# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable

  attr_writer :login

  def login
    @login || self.username || self.email
  end

  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 32 }
  validates_format_of :username, with: /^[a-zA-Z0-9_-]*$/, :multiline => true

  validates :email, length: { maximum: 254 }

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  def authenticatable_salt
    if session_token.nil?
      invalidate_all_sessions!
    end
    "#{super}#{session_token}"
  end

  def invalidate_all_sessions!
    update_attribute(:session_token, SecureRandom.base58(64))
  end
end
