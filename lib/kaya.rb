require "kaya/version"
require "thor"
require 'json'
require 'colorize'
require 'github/markup'
require 'redis'
require 'sidekiq'
require 'mote'
require 'base64'
require 'require_all'

require_rel 'kaya'
require_rel 'generators'

# require_relative "generators/task_rack"


# # Commands
# require_relative "kaya/commands/install"
# require_relative "kaya/commands/start"
# require_relative "kaya/commands/stop"
# require_relative "kaya/commands/restart"
# require_relative "kaya/commands/bye"
# require_relative "kaya/commands/reset"
# require_relative "kaya/commands/reset_tasks"
# require_relative "kaya/commands/help"


# # Custom params
# require_relative "kaya/custom/params"
# require_relative "kaya/custom/execution"


# # Database
# require_relative "kaya/database/mongo_connector"


# # Tasks
# require_relative "kaya/tasks/tasks"
# require_relative "kaya/tasks/task"
# require_relative "kaya/tasks/custom/param"
# require_relative "kaya/tasks/custom/params"


# # Results
# require_relative "kaya/results/results"
# require_relative "kaya/results/result"


# # View
# require_relative "kaya/view/view"
# require_relative "kaya/view/sections"
# require_relative "kaya/view/parser"
# require_relative "kaya/view/parser"


# # API
# require_relative "kaya/API/path"
# require_relative "kaya/API/task"
# require_relative "kaya/API/tasks"
# require_relative "kaya/API/result"
# require_relative "kaya/API/results"
# require_relative "kaya/API/error"
# require_relative "kaya/API/execution"
# require_relative "kaya/API/custom_params"


# # Cucumber relate code
# require_relative "kaya/cucumber/features"


# # Error
# require_relative "kaya/error/errors"

# # Platforms
# require_relative "kaya/platforms/ruby"


# # Support code
# require_relative "kaya/support/logo"
# require_relative "kaya/support/configuration"
# require_relative "kaya/support/clean"
# require_relative "kaya/support/documentation"
# require_relative "kaya/support/console"
# require_relative "kaya/support/notification"
# require_relative "kaya/support/processes"
# require_relative "kaya/support/error_handler_helper"
# require_relative "kaya/support/update"
# require_relative "kaya/support/risk"
# require_relative "kaya/support/request"
# require_relative "kaya/support/files_cleanner"
# require_relative "kaya/support/git"
# require_relative "kaya/support/query_string"
# require_relative "kaya/support/if_config"
# require_relative "kaya/support/time_helper"
# require_relative "kaya/support/logs"
# require_relative "kaya/support/change_inspector"


# # Background jobs
# require_relative "kaya/background_jobs/workers/executor"
# require_relative "kaya/background_jobs/workers/garbage_cleaner"
# require_relative "kaya/background_jobs/sidekiq"


# # Main
# require_relative "kaya/execution"
# require_relative "kaya/cuba"

module Kaya


  if Dir.exist? "#{Dir.pwd}/kaya/logs"

    # Creates kaya_log if it does not exist
    File.open("#{Dir.pwd}/kaya/logs/kaya.log","a+"){} unless File.exist? "#{Dir.pwd}/kaya/logs/kaya.log"

    # Set global conf
    $K_LOG ||= Logger.new("#{Dir.pwd}/kaya/logs/kaya.log",1,1024*1024)
    Kaya::Support::Configuration.get
    $NOTIF ||= Support::Notification.new("#{Dir.pwd.split("/").last}", "#{Kaya::Support::IfConfig.ip}:#{Kaya::Support::Configuration.port}")

  end


  class Base < Thor

    desc "help","If you cannot start kaya"
    def help
      Kaya::Commands.help
    end

    desc "install","Install Kaya on your project"
    def install
      Kaya::Commands.install
    end

    desc "start", "Starts a service waiting for get requests to run tasks you've defined"
    option :nodemon, :required =>false, :type => :boolean, :desc => "Add this flag to no demon use."
    def start
      if Dir.exist? "#{Dir.pwd}/kaya"
        $K_LOG = Logger.new("#{Dir.pwd}/kaya/logs/kaya.log",1,1024*1024)
        Kaya::Commands.start(options["nodemon"])
      else
        puts "

Could not find kaya folder on root project folder. You can use `kaya install`

".red
      end
    end

    desc "stop", "Stop kaya service"
    def stop
      Kaya::Commands.stop
    end

    desc "restart", "Restart Kaya"
    def restart
      Kaya::Commands.restart
    end

    desc "reset","Purges all db registers"
    def reset
      if yes? "Are you sure to reset all register? (yes/no)"
        Kaya::Commands.reset
      end
    end

    desc "reset_tasks","Reset all tasks registers. This command is to purge all tasks from db"
    def reset_tasks
      Kaya::Commands.reset_tasks
    end

    desc "Say bye to kaya", ""
    def bye
      if yes? "Are you sure to say bye to Kaya? (yes/no)"
        Kaya::Commands.bye
      end
    end
  end
end
