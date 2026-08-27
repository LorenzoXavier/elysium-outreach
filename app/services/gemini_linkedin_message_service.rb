# Generates a LinkedIn connection message from a prompt the user has fully
# authored/edited themselves (see Contact#default_linkedin_prompt for the
# template that pre-fills the modal's prompt textarea). Unlike
# GeminiEmailAssistantService, no server-side context injection happens here
# -- the editable prompt *is* the whole instruction, by design (see feature
# requirement: user must be able to edit the full prompt before generating).
class GeminiLinkedinMessageService
  RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: { message: { type: "STRING" } },
    required: %w[message]
  }.freeze

  Result = Struct.new(:message, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def initialize(prompt:)
    @prompt = prompt
  end

  def call
    return Result.new(error: "Please enter a prompt.") if @prompt.blank?

    result = GeminiClient.generate(prompt: wrapped_prompt, schema: RESPONSE_SCHEMA)
    return Result.new(error: result.error) unless result.success?

    Result.new(message: result.data["message"])
  end

  private

  def wrapped_prompt
    <<~PROMPT
      #{@prompt}

      Write only the LinkedIn connection message itself -- plain text, no markdown,
      no surrounding quotes, no placeholders left unfilled, no explanation before or after it.
    PROMPT
  end
end
