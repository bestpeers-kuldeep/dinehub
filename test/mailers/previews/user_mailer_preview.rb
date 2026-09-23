class UserMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    user = User.first || User.new(first_name: "Alex", last_name: "Guest", email: "alex@example.com")
    UserMailer.reset_password_instructions(user, "preview-reset-token")
  end
end
