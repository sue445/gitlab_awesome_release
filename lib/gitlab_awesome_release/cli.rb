require "thor"
require "gitlab_awesome_release"
require "dotenv"

module GitlabAwesomeRelease
  class CLI < Thor
    DEFAULT_VERSION_FORMAT = "^v?[\\d.]+"

    desc "version", "Show gitlab_awesome_release version"
    def version
      puts GitlabAwesomeRelease::VERSION
    end

    desc "create_note", "generate changelog"
    option :filename
    option :from
    option :to
    option :gitlab_api_endpoint
    option :gitlab_api_private_token
    option :gitlab_project_name
    option :allow_tag_format, desc: "Regular expression of tag format", default: "^v?[\\d.]+"
    option :log_level, desc: "Log level (debug|info|warn|error|fatal|unknown)", default: "info"
    def create_note
      Dotenv.load

      gitlab_api_endpoint      = option_or_env!(:gitlab_api_endpoint)
      gitlab_api_private_token = option_or_env!(:gitlab_api_private_token)
      gitlab_project_name      = option_or_env!(:gitlab_project_name)
      allow_tag_format         = option_or_env(:allow_tag_format, DEFAULT_VERSION_FORMAT)

      @logger = Logger.new(STDOUT)
      @logger.level = logger_level(option_or_env(:log_level))
      @logger.formatter = proc{ |severity, datetime, progname, message|
        "[#{datetime}] #{message}\n"
      }

      project = GitlabAwesomeRelease::Project.new(
        api_endpoint:     gitlab_api_endpoint,
        private_token:    gitlab_api_private_token,
        project_name:     gitlab_project_name,
        allow_tag_format: /#{allow_tag_format}/,
        logger:           @logger,
      )

      tag_names = project.release_tag_names
      oldest_tag = option_or_env(:from) || tag_names.first
      newest_tag = option_or_env(:to)   || tag_names.last

      changelog = project.generate_change_log(oldest_tag, newest_tag)

      write_changelog(changelog)
      @logger.info "finish!"
    end

    private

    def option_or_env(name, default = nil)
      upper_name = name.to_s.upcase
      options[name].presence || ENV[upper_name].presence || default
    end

    def option_or_env!(name)
      value = option_or_env(name)
      return value if value

      puts "--#{name.to_s.gsub("_", "-")} or #{name.to_s.upcase} is either required!"
      exit!
    end

    def write_changelog(changelog)
      filename = option_or_env(:filename)
      if filename
        File.open(filename, "wb") do |f|
          f.write(changelog)
        end
        @logger.info "Write to #{filename}"
      else
        puts changelog
      end
    end

    def logger_level(log_level)
      case log_level.to_sym
      when :debug
        Logger::DEBUG
      when :error
        Logger::ERROR
      when :fatal
        Logger::FATAL
      when :info
        Logger::INFO
      when :unknown
        Logger::UNKNOWN
      when :warn
        Logger::WARN
      else
        raise "Unknown log_level: #{log_level}"
      end
    end
  end
end
