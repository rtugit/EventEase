module ImageHelper
  # Renders images with Cloudinary when available, falls back to ActiveStorage/local assets otherwise.
  # Handles responsive transformations for both Cloudinary and local storage.
  #
  # Usage:
  #   responsive_image(current_user)                              # defaults to :photo (has_one_attached)
  #   responsive_image(event, :photos)                            # has_many_attached, uses first
  #   responsive_image(current_user, :avatar, "fallback.svg")     # custom attachment name and fallback
  #   responsive_image(event, :photos, height: 600, width: 1200)  # with transformations
  #
  def responsive_image(record, key = :photo, fallback = "eventease-logo.svg", attachment: nil, **options)
    classes = options.delete(:class)

    # Extract Cloudinary transformation options
    cloudinary_transforms = {}
    %i[height width crop gravity quality].each do |attr|
      cloudinary_transforms[attr] = options.delete(attr) if options.key?(attr)
    end

    # Get the attachment - handle both has_one and has_many
    att = attachment
    if att.nil? && record
      attr = begin
        record.public_send(key)
      rescue StandardError
        nil
      end
      # If it's a collection (has_many_attached), get the first blob
      if attr.respond_to?(:first)
        att = attr.first&.blob
      else
        # For has_one_attached, get the blob
        att = attr&.blob
      end
    end

    cloud_available = ENV["CLOUDINARY_URL"].present?
    attached = att.present?
    blob_key = att.respond_to?(:key) ? att.key : nil

    html_options = { class: classes }.compact.merge(options)

    if cloud_available && blob_key.present?
      # Use Cloudinary with transformations
      cl_image_tag(blob_key, cloudinary_transforms.merge(html_options))
    elsif attached
      # Use ActiveStorage - apply CSS styling instead of server-side transforms
      image_tag(att, html_options)
    else
      # Fallback image
      image_tag(fallback, html_options)
    end
  rescue StandardError => e
    Rails.logger.warn("Image rendering error for #{record.class}##{key}: #{e.message}")
    image_tag(fallback, { class: classes }.compact)
  end
end
