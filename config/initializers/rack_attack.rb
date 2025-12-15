class Rack::Attack
  # Throttle registration creation to 5 requests per minute per IP
  throttle('registrations/ip', limit: 5, period: 60) do |req|
    if req.path.start_with?('/events/') && req.path.include?('/registrations') && req.post?
      req.ip
    end
  end

  # Throttle registration creation to 10 requests per minute per user
  throttle('registrations/user', limit: 10, period: 60) do |req|
    if req.path.start_with?('/events/') && req.path.include?('/registrations') && req.post?
      req.session[:user_id] if req.session[:user_id]
    end
  end
end

# Customize the error response for rate limit
Rack::Attack.throttled_responder = lambda do |_req|
  match_data = _req.env['rack.attack.match_data']
  retry_after = match_data[:retry_after]

  [
    429,
    { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
    [{ error: 'Too many registration requests. Please try again later.' }.to_json]
  ]
end

