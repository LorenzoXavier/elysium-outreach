require "net/http"
require "json"

# Calls the Gemini API to draft or refine an outreach email subject/body from a
# free-text prompt, optionally given the current draft and/or a Contact for
# context. Uses Gemini's structured-output mode (responseSchema) so the reply
# is always valid {"subject": "...", "body": "..."} JSON -- no fragile
# prompt-based parsing.
class GeminiEmailAssistantService
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%<model>s:generateContent"
  RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: { subject: { type: "STRING" }, body: { type: "STRING" } },
    required: %w[subject body]
  }.freeze

  Result = Struct.new(:subject, :body, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def initialize(prompt:, subject: nil, body: nil, contact: nil)
    @prompt = prompt
    @subject = subject
    @body = body
    @contact = contact
  end

  def call
    return Result.new(error: "Please enter a prompt for the AI assistant.") if @prompt.blank?

    api_key = ENV["GEMINI_API_KEY"]
    return Result.new(error: "GEMINI_API_KEY is not configured.") if api_key.blank?

    parse(post(api_key))
  rescue Timeout::Error, SocketError, SystemCallError => e
    Result.new(error: "Could not reach Gemini: #{e.message}")
  end

  private

  def post(api_key)
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
      contents: [ { parts: [ { text: full_prompt } ] } ],
      generationConfig: { responseMimeType: "application/json", responseSchema: RESPONSE_SCHEMA }
    }.to_json

    http.request(request)
  end

  def full_prompt
    <<~PROMPT
      You are an outreach email copywriter helping draft a short, professional
      cold/warm outreach email. #{context_lines.join(" ")}

      Instruction from the user: #{@prompt}

      Write a concise subject line and a short email body (plain text, no markdown,
      no placeholders like [Name] left unfilled -- use the context given).
    PROMPT
  end

  def context_lines
    lines = []
    if @contact
      who = [ @contact.display_name, @contact.title, @contact.company ].select(&:present?).join(", ")
      lines << "Recipient: #{who}." if who.present?
    end
    lines << "Current subject draft (revise, don't ignore, unless the instruction says to start over): #{@subject}" if @subject.present?
    lines << "Current body draft (revise, don't ignore, unless the instruction says to start over): #{@body}" if @body.present?
    lines
  end

  def parse(response)
    unless response.is_a?(Net::HTTPSuccess)
      return Result.new(error: "Gemini API error (#{response.code}): #{response.body.to_s.truncate(300)}")
    end

    data = JSON.parse(response.body)
    text = data.dig("candidates", 0, "content", "parts", 0, "text")
    return Result.new(error: "Gemini returned no content.") if text.blank?

    json = JSON.parse(text)
    Result.new(subject: json["subject"], body: json["body"])
  rescue JSON::ParserError => e
    Result.new(error: "Could not parse Gemini's response: #{e.message}")
  end
end
