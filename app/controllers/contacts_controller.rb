class ContactsController < ApplicationController
  before_action :set_contact, except: [ :new, :create, :bulk_mark_linkedin_outreached ]

  def show
  end

  # Manual lead entry: not part of any CSV import batch, so it's always unique
  # and defaults to green (high) priority -- someone bothered to type it in by hand.
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params.merge(duplicate_status: :unique, priority_status: :green))

    if @contact.save
      redirect_to @contact, notice: "#{@contact.display_name} added to the pipeline."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to @contact, notice: "Contact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_priority
    @contact.update!(priority_status: params.require(:priority_status))
    redirect_back fallback_location: root_path, notice: "Priority updated to #{@contact.priority_label}."
  end

  def mark_linkedin_outreached
    @contact.mark_linkedin_outreached!
    redirect_back fallback_location: root_path, notice: "LinkedIn outreach recorded for #{@contact.display_name}."
  end

  def bulk_mark_linkedin_outreached
    contacts = Contact.where(id: params[:contact_ids])

    if contacts.none?
      redirect_back fallback_location: root_path, alert: "No contacts selected." and return
    end

    contacts.find_each(&:mark_linkedin_outreached!)
    redirect_back fallback_location: root_path, notice: "LinkedIn outreach recorded for #{contacts.size} contact(s)."
  end

  def edit_email
  end

  def update_email
    @contact.update!(email_body: params[:contact][:email_body], email_status: :drafted)
    redirect_to edit_email_contact_path(@contact), notice: "Draft saved."
  end

  def publish_email
    if @contact.email.blank?
      redirect_to edit_email_contact_path(@contact), alert: "This contact has no email address on file." and return
    end

    @contact.update!(email_body: params.dig(:contact, :email_body) || @contact.email_body)
    OutreachMailer.outreach_email(@contact).deliver_later
    @contact.update!(email_status: :sent, email_sent_at: Time.current)

    redirect_to root_path, notice: "Email sent to #{@contact.display_name}."
  end

  # Composer: pick a template (client-side prefill, see email_composer_controller.js)
  # or write custom subject/body, then choose a future date/time to schedule delivery.
  def new_scheduled_email
    @scheduled_email = @contact.scheduled_emails.build
    @email_templates = EmailTemplate.order(:name)
  end

  def schedule_email
    @scheduled_email = @contact.scheduled_emails.build(scheduled_email_params)

    if @contact.email.blank?
      @email_templates = EmailTemplate.order(:name)
      @scheduled_email.errors.add(:base, "This contact has no email address on file.")
      render :new_scheduled_email, status: :unprocessable_entity and return
    end

    if @scheduled_email.save
      ScheduledContactEmailJob.set(wait_until: @scheduled_email.scheduled_at).perform_later(@scheduled_email.id)
      redirect_to @contact, notice: "Email scheduled for #{@scheduled_email.scheduled_at.to_fs(:long)}."
    else
      @email_templates = EmailTemplate.order(:name)
      render :new_scheduled_email, status: :unprocessable_entity
    end
  end

  # "Send Now" on the same composer -- delivers immediately instead of
  # enqueuing, reusing ScheduledEmail#deliver! so the outcome (sent/failed)
  # and the Contact side-effects stay consistent with the scheduled path.
  def send_email_now
    @scheduled_email = @contact.scheduled_emails.build(scheduled_email_params.except(:scheduled_at))
    @scheduled_email.scheduled_at = Time.current
    @scheduled_email.send_immediately = true

    if @contact.email.blank?
      @email_templates = EmailTemplate.order(:name)
      @scheduled_email.errors.add(:base, "This contact has no email address on file.")
      render :new_scheduled_email, status: :unprocessable_entity and return
    end

    unless @scheduled_email.save
      @email_templates = EmailTemplate.order(:name)
      render :new_scheduled_email, status: :unprocessable_entity and return
    end

    @scheduled_email.deliver!

    if @scheduled_email.sent?
      redirect_to @contact, notice: "Email sent to #{@contact.display_name}."
    else
      redirect_to @contact, alert: "Could not send: #{@scheduled_email.error_message}"
    end
  end

  # Opens the "Draft LinkedIn Message" modal (loaded into the layout's
  # #modal turbo-frame). Only reachable when the contact hasn't been
  # outreached yet -- see the trigger button's conditional in the views.
  # layout: false -- this is only ever fetched via a turbo-frame request, and
  # rendering it inside the full layout would put two id="modal" elements in
  # one response (this one, plus the layout's own empty placeholder).
  def new_linkedin_message
    @linkedin_prompt = @contact.default_linkedin_prompt
    render layout: false
  end

  # AI Assistant "Generate with Gemini": renders into a preview area only --
  # never touches the editable message textarea directly. The user must
  # click "Apply Suggestion" (client-side, see linkedin_message_controller.js)
  # to copy it across.
  def generate_linkedin_message
    result = GeminiLinkedinMessageService.new(prompt: params[:prompt]).call

    render turbo_stream: turbo_stream.replace(
      "linkedin_message_preview",
      partial: "contacts/linkedin_message_preview",
      locals: { result: result }
    )
  end

  # Saves whatever is currently in the editable message textarea (default
  # template text, an applied AI suggestion, or a free-hand edit -- the
  # server doesn't care which) and marks LinkedIn outreach complete in the
  # same stroke, matching the plain "Mark LinkedIn Outreached" action's
  # side effects (follow-up due date, etc).
  def save_linkedin_message
    @contact.mark_linkedin_outreached!(message: params[:linkedin_message])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @contact, notice: "LinkedIn outreach recorded for #{@contact.display_name}." }
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :full_name, :first_name, :last_name, :company, :title, :email, :phone,
      :linkedin_url, :website, :location, :notes, :source
    )
  end

  def scheduled_email_params
    params.require(:scheduled_email).permit(:email_template_id, :subject, :body, :scheduled_at)
  end
end
