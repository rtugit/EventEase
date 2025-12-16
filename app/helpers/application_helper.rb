module ApplicationHelper
  def render_avatar(resource, size: 32, css_class: "")
    # Try to resolve the user object:
    # 1. From the registration relation
    # 2. By looking up the email (for guests who are users but checking out as guest)
    # 3. Or use the resource itself if it's already a User
    user = if resource.is_a?(Registration)
             resource.user || User.find_by(email: resource.email)
           else
             resource
           end

    name = resource.respond_to?(:name) && resource.name.present? ? resource.name : (user&.first_name || "U")

    # Check if user exists and has a photo attached
    if user&.photo&.attached?
      image_tag(user.photo,
                class: "avatar-image #{css_class}",
                style: "width: #{size}px; height: #{size}px; object-fit: cover;",
                alt: name)
    else
      # Fallback to Initials
      # Using size / 2.2 to provide a better ratio (e.g. 24px -> ~11px, 32px -> ~14.5px)
      content_tag(:div, class: "avatar-initials #{css_class}", style: "font-size: #{size / 2.2}px;") do
        name.first.upcase
      end
    end
  end
end
