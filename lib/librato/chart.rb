class Librato::Chart < OpenStruct
  include Librato::Utils
  attr_reader :creation_response

  REQUIRED_KEYS = [
    :space_id,
    :type,
    :name,
    :streams
  ]

  def save
    self.class.new safe_parse(creation_response.response_body) if valid?
  end

  private

  def valid?
    REQUIRED_KEYS.none?{ |k| send(k).nil? }
  end

  def chart_url
    "#{SPACES_URL}/#{space_id}/charts"
  end

  def creation_response
    @creation_response ||= client(chart_url, body: creation_payload, method: :post).run
  end

  def creation_payload
    {
      type:    type,
      name:    name,
      streams: streams
    }
  end
end
