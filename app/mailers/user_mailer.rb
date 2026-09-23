class UserMailer < ApplicationMailer
  def reset_password_instructions(user, raw_token)
    @user = user
    @reset_password_url = user.reset_password_url(raw_token)

    mail to: user.email, subject: "Reset your DineHub password"
  end
end
