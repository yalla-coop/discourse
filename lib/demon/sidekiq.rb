# frozen_string_literal: true

require "demon/base"

class Demon::Sidekiq < ::Demon::Base
  def self.prefix
    "sidekiq"
  end

  def self.after_fork(&blk)
    blk ? (@blk = blk) : @blk
  end

  private

  def suppress_stdout
    false
  end

  def suppress_stderr
    false
  end

  def log_in_trap(message, level: :info)
    SignalTrapLogger.instance.log(@logger, message, level: level)
  end

  def after_fork
    Demon::Sidekiq.after_fork&.call
    SignalTrapLogger.instance.after_fork

    log("Loading Sidekiq in process id #{Process.pid}")
    require "sidekiq/cli"
    cli = Sidekiq::CLI.instance

    # Unicorn uses USR1 to indicate that log files have been rotated
    Signal.trap("USR1") do
      begin
        log_in_trap("Sidekiq reopening logs...")
        Unicorn::Util.reopen_logs
        log_in_trap("Sidekiq done reopening logs...")
      rescue => error
        log_in_trap(
          "Error encountered while reopening logs: [#{error.class}] #{error.message}\n#{error.backtrace.join("\n")}",
          level: :error,
        )

        exit 1
      end
    end

    options = ["-c", GlobalSetting.sidekiq_workers.to_s]

    [["critical", 8], ["default", 4], ["low", 2], ["ultra_low", 1]].each do |queue_name, weight|
      custom_queue_hostname = ENV["UNICORN_SIDEKIQ_#{queue_name.upcase}_QUEUE_HOSTNAME"]

      if !custom_queue_hostname || custom_queue_hostname.split(",").include?(Discourse.os_hostname)
        options << "-q"
        options << "#{queue_name},#{weight}"
      end
    end

    # Sidekiq not as high priority as web, in this environment it is forked so a web is very
    # likely running
    Discourse::Utils.execute_command("renice", "-n", "5", "-p", Process.pid.to_s)

    cli.parse(options)
    load Rails.root + "config/initializers/100-sidekiq.rb"
    cli.run
  rescue => error
    log(
      "Error encountered while starting Sidekiq: [#{error.class}] #{error.message}\n#{error.backtrace.join("\n")}",
      level: :error,
    )

    exit 1
  end
end
