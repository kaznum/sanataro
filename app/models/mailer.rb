# -*- coding: utf-8 -*-
class Mailer < ActionMailer::Base
  def signup_confirmation(user)
    @user = user
    mail(to: user.email, from: Settings.system_mail_address, subject: "[#{Settings.product_name}] #{I18n.t('mailer.subject.not_registered_user_yet')}")
  end
  
  def signup_complete(user)
    @user = user
    mail(to: user.email, from: Settings.system_mail_address, subject: "[#{Settings.product_name}] #{I18n.t('mailer.subject.registered_user_successfully')}")
  end
end



