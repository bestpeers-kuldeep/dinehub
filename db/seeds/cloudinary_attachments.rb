# Re-uploads local Active Storage files to Cloudinary and rewrites stored URLs.
# Loaded from db/seeds.rb. To run on existing data without reseeding:
#   bin/rails runner db/seeds/cloudinary_attachments.rb

ATTACHMENT_MIGRATIONS = [
  { klass: MenuItem, name: :image, column: :image_url },
  { klass: EventItem, name: :logo, column: :logo_url },
  { klass: Career, name: :resume, column: :resume_link }
].freeze

def cloudinary_storage?
  Rails.application.config.active_storage.service.to_s == "cloudinary"
end

def refresh_stored_attachment_url!(record, attachment_name, column)
  attachment = record.public_send(attachment_name)
  return unless attachment.attached?

  url = record.send(:synced_attachment_url, attachment)
  record.update_column(column, url) if record.public_send(column) != url
end

def migrate_attachment_to_cloudinary!(record, attachment_name, column)
  attachment = record.public_send(attachment_name)
  return unless attachment.attached?

  blob = attachment.blob
  if blob.service_name.to_s == "cloudinary"
    refresh_stored_attachment_url!(record, attachment_name, column)
    return :already_cloudinary
  end

  io = StringIO.new(blob.download)
  filename = blob.filename.to_s
  content_type = blob.content_type

  attachment.purge
  attachment.attach(io: io, filename: filename, content_type: content_type)
  record.reload
  refresh_stored_attachment_url!(record, attachment_name, column)
  :uploaded
rescue StandardError => e
  warn "Cloudinary migrate failed for #{record.class.name}##{record.id} #{attachment_name}: #{e.class} #{e.message}"
  :failed
end

def migrate_all_attachments_to_cloudinary!
  unless cloudinary_storage?
    puts "Skipping Cloudinary attachment migrate (active_storage.service is #{Rails.application.config.active_storage.service})"
    return
  end

  counts = { uploaded: 0, already_cloudinary: 0, failed: 0, skipped: 0 }

  ATTACHMENT_MIGRATIONS.each do |config|
    config[:klass].find_each do |record|
      attachment = record.public_send(config[:name])
      unless attachment.attached?
        counts[:skipped] += 1
        next
      end

      result = migrate_attachment_to_cloudinary!(record, config[:name], config[:column])
      counts[result] += 1 if counts.key?(result)
    end
  end

  puts "Cloudinary attachments: uploaded=#{counts[:uploaded]} already=#{counts[:already_cloudinary]} skipped=#{counts[:skipped]} failed=#{counts[:failed]}"
end

migrate_all_attachments_to_cloudinary!
