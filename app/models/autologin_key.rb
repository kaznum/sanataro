class AutologinKey < ActiveRecord::Base
  attr_accessor :autologin_key
  attr_protected :user_id

  belongs_to :user
  validates_presence_of :autologin_key, :if => :required_key?
  validates_presence_of :user_id

  before_save :fill_enc_autologin_key

  scope :active, lambda { where("created_at > ?", Time.now - 30 * 24 * 3600) }

  class << self
    def matched_key(user_id, plain_key)
      user = User.find_by_id(user_id)
      return nil if user.nil?

      keys = AutologinKey.active.where(user_id: user_id)

      keys.each do |k|
        if CommonUtil.correct_password?(user.login+plain_key, k.enc_autologin_key)
          return k
        end
      end
      nil
    end

    def cleanup(user_id)
      AutologinKey.delete_all(["created_at < ?", Time.now - (30 * 24 * 3600)])
    end
  end

  private

  def required_key?
    self.enc_autologin_key.nil?
  end

  def fill_enc_autologin_key
    if self.autologin_key.present? && self.user_id.present?
      user = User.find_by_id(self.user_id)
      self.enc_autologin_key = CommonUtil.crypt(user.login + self.autologin_key) if user
    end
  end
end
