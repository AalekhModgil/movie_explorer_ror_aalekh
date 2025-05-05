class FcmService
  def initialize
    @client = FCM.new(ENV['FCM_SERVER_KEY'])
    raise 'Failed to initialize FCM client' if @client.nil?
  end

  def send_notification(device_tokens, title, body, data = {})
    tokens = Array(device_tokens).map(&:to_s).reject(&:empty?)
    return { status_code: 200, body: 'No valid device tokens' } if tokens.empty?
    options = {
      notification: {
        title: title,
        body: body
      },
      data: data
    }
    response = @client.send(tokens, options)
    response
  end
end