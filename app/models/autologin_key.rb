# frozen_string_literal: true

class AutologinKey < ActiveRecord::Base
  attr_accessor :autologin_key

  belongs_to :user
  validates :autologin_key, presence: { if: :key_required? }
  validates :user_id, presence: true

  before_save :fill_enc_autologin_key

  scope :active, -> { where('created_at > ?', Time.now - 30 * 24 * 3600) }

  class << self
    def matched_key(user_id, plain_key)
      user = User.find_by_id(user_id)
      return nil unless user

      AutologinKey.active.where(user_id: user_id).find { |k| CommonUtil.correct_password?(user.login + plain_key, k.enc_autologin_key) }
    end

    def cleanup
      AutologinKey.delete_all(['created_at < ?', Time.now - (30 * 24 * 3600)])
    end
  end

  private

  def key_required?
    enc_autologin_key.nil?
  end

  def fill_enc_autologin_key
    return unless autologin_key.present? && user_id.present?

    user = User.find_by_id(user_id)
    self.enc_autologin_key = CommonUtil.crypt(user.login + autologin_key) if user
  end
end
