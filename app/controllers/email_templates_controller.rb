class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: [ :show, :edit, :update, :destroy ]

  def index
    @email_templates = EmailTemplate.order(:name)
  end

  def show
  end

  def new
    @email_template = EmailTemplate.new
  end

  def edit
  end

  def create
    @email_template = EmailTemplate.new(email_template_params)

    if @email_template.save
      redirect_to @email_template, notice: "Template created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @email_template.update(email_template_params)
      redirect_to @email_template, notice: "Template updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_template.destroy
    redirect_to email_templates_path, notice: "Template deleted."
  end

  # AI Assistant: never touches the DB or the visible form fields directly --
  # it only renders a suggestion the user must explicitly apply (see
  # app/javascript/controllers/ai_assistant_controller.js).
  def ai_draft
    result = GeminiEmailAssistantService.new(
      prompt: params[:prompt],
      subject: params[:current_subject],
      body: params[:current_body]
    ).call

    render turbo_stream: turbo_stream.replace(
      "ai_suggestion_drawer",
      partial: "email_templates/ai_suggestion_drawer",
      locals: { result: result }
    )
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:name, :subject, :body)
  end
end
