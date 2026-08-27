class ContactsController < ApplicationController
  before_action :set_contact, except: [:bulk_mark_linkedin_outreached]

  def show
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
    redirect_back fallback_location: root_path, notice: "Priority updated to #{@contact.priority_status.capitalize}."
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
    @contact.update!(email_status: :sent)

    redirect_to root_path, notice: "Email sent to #{@contact.display_name}."
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
end
