module ImageHelper
  # Renders images with Cloudinary when available, falls back to ActiveStorage/local assets otherwise.
  # Usage:
  #   responsive_image(current_user)                              # defaults to :photo
  #   responsive_image(current_user, :avatar, class: "avatar")   # custom attachment name
  #   responsive_image(nil, attachment: event.photos.first)       # pass a direct attachment
  #
  def responsive_image(record, key = :photo, fallback = "eventease-logo.svg", attachment: nil, **options)
    classes = options.delete(:class)
    att = attachment || record&.public_send(key) rescue nil

    cloud_available = ENV["CLOUDINARY_URL"].present?
    attached = att.respond_to?(:attached?) ? att.attached? : att.present?
    blob_key = att.respond_to?(:key) ? att.key : nil

    if cloud_available && blob_key.present?
      cl_image_tag(blob_key, { class: classes }.compact, **options)
    elsif attached
      image_tag(att, { class: classes }.compact, **options)
    else
      image_tag(fallback, { class: classes }.compact, **options)
    end
  rescue StandardError => e
    Rails.logger.warn("Image rendering error: #{e.message}")
    image_tag(fallback, { class: classes }.compact, **options)
  end
end
