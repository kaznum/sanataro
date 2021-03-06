# frozen_string_literal: true

class Mailer < ActionMailer::Base
  def signup_confirmation(user)
    @user = user
    mail(to: user.email, from: GlobalSettings.system_mail_address, subject: "[#{GlobalSettings.product_name}] #{I18n.t('mailer.subject.not_registered_user_yet')}")
  end

  def signup_complete(user)
    @user = user
    mail(to: user.email, from: GlobalSettings.system_mail_address, subject: "[#{GlobalSettings.product_name}] #{I18n.t('mailer.subject.registered_user_successfully')}")
  end
end
