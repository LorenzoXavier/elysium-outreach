# Delivers a ScheduledEmail at its chosen time. Enqueued via
# `ScheduledContactEmailJob.set(wait_until: scheduled_email.scheduled_at).perform_later(scheduled_email.id)`
# from ContactsController#schedule_email. Runs on Solid Queue -- that's set
# globally via `config.active_job.queue_adapter = :solid_queue` in
# config/environments/{development,production}.rb, not per-job; `queue_as`
# below just names the queue for prioritization/filtering, which the default
# Solid Queue worker (queues: "*" in config/queue.yml) processes regardless.
class ScheduledContactEmailJob < ApplicationJob
  queue_as :scheduled_emails

  # A destroyed ScheduledEmail (or its Contact) simply means there's nothing
  # left to send -- not a failure worth retrying or raising about.
  discard_on ActiveJob::DeserializationError

  def perform(scheduled_email_id)
    scheduled_email = ScheduledEmail.find_by(id: scheduled_email_id)
    return if scheduled_email.nil?

    scheduled_email.deliver!
  end
end
