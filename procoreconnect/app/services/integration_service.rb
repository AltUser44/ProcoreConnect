require "httparty"

# Outbound HTTP client for a single Integration. Wraps HTTParty so the rest
# of the app talks in terms of an `IntegrationService::Result` value object
# instead of HTTParty::Response, and centralizes auth header handling.
class IntegrationService
  Result = Struct.new(:success, :status_code, :body, :error_message, keyword_init: true) do
    def success?
      success == true
    end

    def failure?
      !success?
    end
  end

  DEFAULT_TIMEOUT = 10 # seconds

  attr_reader :integration

  def initialize(integration)
    raise ArgumentError, "integration must be persisted" if integration.nil? || integration.id.nil?

    @integration = integration
  end

  # Send a payload to the integration's api_endpoint. Returns a Result
  # whether the call succeeded or failed; never raises on transport errors.
  def deliver(payload, event_type: nil)
    response = HTTParty.post(
      integration.api_endpoint,
      body: build_body(payload, event_type),
      headers: build_headers(event_type),
      timeout: DEFAULT_TIMEOUT
    )

    if response.code.between?(200, 299)
      Result.new(success: true, status_code: response.code, body: parsed_body(response))
    else
      Result.new(
        success: false,
        status_code: response.code,
        body: parsed_body(response),
        error_message: "HTTP #{response.code}"
      )
    end
  rescue HTTParty::Error,
         Net::OpenTimeout,
         Net::ReadTimeout,
         Errno::ECONNREFUSED,
         SocketError => e
    Result.new(
      success: false,
      status_code: nil,
      body: nil,
      error_message: "#{e.class.name}: #{e.message}"
    )
  end

  private

  def build_headers(event_type)
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "User-Agent" => "ProcoreConnect/1.0"
    }
    headers["Authorization"] = "Bearer #{integration.api_key}" if integration.api_key.present?
    headers["X-Event-Type"] = event_type if event_type.present?
    headers
  end

  def build_body(payload, event_type)
    {
      integration_id: integration.id,
      integration_name: integration.name,
      event_type: event_type,
      payload: payload,
      delivered_at: Time.current.iso8601
    }.to_json
  end

  def parsed_body(response)
    JSON.parse(response.body || "")
  rescue JSON::ParserError
    response.body
  end
end
