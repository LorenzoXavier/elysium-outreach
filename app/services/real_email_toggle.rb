# Development-only switch controlling whether outgoing mail actually goes to
# real SMTP (Gmail) or gets rerouted to local Mailpit. Backed by a flag file
# in tmp/ (not Rails.cache -- the default :memory_store is per-process, and
# `bin/dev` runs the web server and the Solid Queue job worker as separate
# processes, so a cache-backed toggle set from the browser would never be
# seen by scheduled-email jobs). A file on disk is trivially shared by every
# local process. Defaults OFF (Mailpit) so real emails are never sent by
# accident.
class RealEmailToggle
  FLAG_FILE = Rails.root.join("tmp", "real_email_toggle_on")

  class << self
    def enabled?
      FLAG_FILE.exist?
    end

    def enable!
      FileUtils.touch(FLAG_FILE)
    end

    def disable!
      FileUtils.rm_f(FLAG_FILE)
    end

    def toggle!
      enabled? ? disable! : enable!
    end
  end
end
