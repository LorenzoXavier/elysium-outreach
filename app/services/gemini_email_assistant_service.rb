# Drafts or refines an outreach email subject/body from a free-text prompt,
# optionally given the current draft and/or a Contact for context. Delegates
# the actual API call to GeminiClient (shared with every other AI-assist
# feature) and just supplies the email-specific prompt wrapping + schema.
class GeminiEmailAssistantService
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

    result = GeminiClient.generate(prompt: full_prompt, schema: RESPONSE_SCHEMA)
    return Result.new(error: result.error) unless result.success?

    Result.new(subject: result.data["subject"], body: result.data["body"])
  end

  private

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
end
