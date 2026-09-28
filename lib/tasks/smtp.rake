namespace :smtp do
  desc "Check that the configured SMTP host/port is reachable and the credentials work"
  task check: :environment do
    settings = ActionMailer::Base.smtp_settings
    address = settings[:address]
    port = settings[:port]

    puts "SMTP target: #{address}:#{port} (user #{settings[:user_name]})"

    begin
      Socket.tcp(address, port, connect_timeout: settings[:open_timeout] || 10).close
      puts "TCP connect: OK"
    rescue Errno::ETIMEDOUT, Net::OpenTimeout, IO::TimeoutError
      abort "TCP connect: TIMED OUT — the port is blocked by the host (Render blocks 25/465/587 on free instances). Try port 2525 or switch to an HTTPS mail API."
    rescue StandardError => e
      abort "TCP connect: FAILED — #{e.class}: #{e.message}"
    end

    recipient = ENV.fetch("TO") { ENV.fetch("MAILER_FROM") }
    Mail.new(
      from: ENV.fetch("MAILER_FROM"),
      to: recipient,
      subject: "DineHub SMTP check",
      body: "Sent from #{Rails.env} at #{Time.current}."
    ).tap { |m| m.delivery_method(:smtp, settings) }.deliver!

    puts "Delivery: OK — sent to #{recipient}"
  end
end
