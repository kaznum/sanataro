class AutologinKey < ActiveRecord::Base
  attr_accessor :autologin_key
  attr_protected :user_id

  belongs_to :user
  validates_presence_of :autologin_key, :if => :required_key?
  validates_presence_of :user_id

  before_save :fill_enc_autologin_key

  scope :active, lambda { where("created_at > ?", Time.now - 30 * 24 * 3600) }
  
  def AutologinKey.matched_key(user_id, plain_key)
    user = User.find_by_id(user_id)
    return nil if user.nil?

    keys = AutologinKey.active.where("user_id = ?", user_id)

    keys.each do |k|
      if CommonUtil.check_password(user.login+plain_key, k.enc_autologin_key)
        return k
      end
    end

    return nil
  end

  def AutologinKey.cleanup(user_id)
    AutologinKey.delete_all(["created_at < ?", Time.now - (30 * 24 * 3600)])
  end
  
  private

  def required_key?
    self.enc_autologin_key.nil?
  end

  def fill_enc_autologin_key
    if (not self.autologin_key.nil?) && (not self.user_id.nil?)
      user = User.find_by_id(self.user_id)
      self.enc_autologin_key = CommonUtil.crypt(user.login + self.autologin_key) if user
    end
  end
  
end
