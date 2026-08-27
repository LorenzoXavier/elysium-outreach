require "net/http"
require "json"

# Low-level Gemini API client shared by every AI-assist feature in the app
# (email drafting, LinkedIn messages, ...). Handles the HTTP request and
# Gemini's structured-output mode (responseSchema); callers just supply a
# fully-formed prompt + a JSON schema and get back a parsed Hash or an error
# -- no per-feature duplication of endpoint/auth/HTTP-error handling.
class GeminiClient
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%<model>s:generateContent"

  Result = Struct.new(:data, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def self.generate(prompt:, schema:)
    new.generate(prompt: prompt, schema: schema)
  end

  def generate(prompt:, schema:)
    return Result.new(error: "Please enter a prompt.") if prompt.blank?

    api_key = ENV["GEMINI_API_KEY"]
    return Result.new(error: "GEMINI_API_KEY is not configured.") if api_key.blank?

    parse(post(api_key, prompt, schema))
  rescue Timeout::Error, SocketError, SystemCallError => e
    Result.new(error: "Could not reach Gemini: #{e.message}")
  end

  private

  def post(api_key, prompt, schema)
    model = ENV.fetch("GEMINI_MODEL", "gemini-2.5-flash")
    uri = URI(format(ENDPOINT, model: model))
    uri.query = URI.encode_www_form(key: api_key)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: { responseMimeType: "application/json", responseSchema: schema }
    }.to_json

    http.request(request)
  end

  def parse(response)
    unless response.is_a?(Net::HTTPSuccess)
      return Result.new(error: "Gemini API error (#{response.code}): #{response.body.to_s.truncate(300)}")
    end

    data = JSON.parse(response.body)
    text = data.dig("candidates", 0, "content", "parts", 0, "text")
    return Result.new(error: "Gemini returned no content.") if text.blank?

    Result.new(data: JSON.parse(text))
  rescue JSON::ParserError => e
    Result.new(error: "Could not parse Gemini's response: #{e.message}")
  end
end
