require "thor"
require "gitlab_awesome_release"
require "dotenv"

module GitlabAwesomeRelease
  require "logger"

  class CLI < Thor
    DEFAULT_VERSION_FORMAT = "^v?[\\d.]+".freeze
    GITLAB_ENV_FILES = %w(.env.gitlab ~/.env.gitlab).freeze

    GITLAB_API_DESCRIPTION               = "GitLab API endpoint (e.g. http://example.com/api/v4)".freeze
    GITLAB_API_PRIVATE_TOKEN_DESCRIPTION = "Your private token".freeze
    GITLAB_API_PROJECT_NAME              = "Target project (e.g. group/repo_name)".freeze
    LOG_LEVEL_DESCRIPTION                = "Log level (debug|info|warn|error|fatal|unknown)".freeze

    desc "version", "Show gitlab_awesome_release version"
    def version
      puts GitlabAwesomeRelease::VERSION
    end

    desc "create_note", "generate changelog"
    option :gitlab_api_endpoint,      desc: GITLAB_API_DESCRIPTION
    option :gitlab_api_private_token, desc: GITLAB_API_PRIVATE_TOKEN_DESCRIPTION
    option :gitlab_project_name,      desc: GITLAB_API_PROJECT_NAME
    option :from_tag,                 desc: "The first tag to create a changelog (default: oldest tag)"
    option :to_tag,                   desc: "The last tag to create a changelog (default: latest tag)"
    option :filename,                 desc: "Filepath to changelog file (e.g. CHANGELOG.md). if empty, output to console"
    option :allow_tag_format,         desc: "Tag format for release note heading (regular expresion pattern)", default: DEFAULT_VERSION_FORMAT
    option :log_level,                desc: LOG_LEVEL_DESCRIPTION, default: "info"
    def create_note
      Dotenv.load(*GITLAB_ENV_FILES)

      project = create_project

      tag_names = project.release_tag_names
      oldest_tag = option_or_env(:from_tag) || tag_names.first
      newest_tag = option_or_env(:to_tag)   || tag_names.last

      changelog = project.generate_change_log(oldest_tag, newest_tag)

      write_changelog(changelog)
      @logger.info "finish!"
    end

    desc "create_latest_note", "generate release note only latest version and unreleased"
    option :gitlab_api_endpoint,      desc: GITLAB_API_DESCRIPTION
    option :gitlab_api_private_token, desc: GITLAB_API_PRIVATE_TOKEN_DESCRIPTION
    option :gitlab_project_name,      desc: GITLAB_API_PROJECT_NAME
    option :filename,                 desc: "Filepath to changelog file (e.g. CHANGELOG.md). if empty, output to console"
    option :allow_tag_format,         desc: "Tag format for release note heading (regular expresion pattern)", default: DEFAULT_VERSION_FORMAT
    option :log_level,                desc: LOG_LEVEL_DESCRIPTION, default: "info"
    def create_latest_note
      Dotenv.load(*GITLAB_ENV_FILES)

      project = create_project

      tag_names = project.release_tag_names

      changelog =
        if tag_names.count >= 2
          project.generate_change_log(tag_names[-2], tag_names[-1])
        elsif tag_names.count == 1
          project.generate_change_log(tag_names[0], tag_names[0])
        end

      write_changelog(changelog) if changelog
      @logger.info "finish!"
    end

    desc "marking", "Add version label to MergeRequests"
    option :gitlab_api_endpoint,      desc: GITLAB_API_DESCRIPTION
    option :gitlab_api_private_token, desc: GITLAB_API_PRIVATE_TOKEN_DESCRIPTION
    option :gitlab_project_name,      desc: GITLAB_API_PROJECT_NAME
    option :from_tag,                 desc: "The first tag to marking"
    option :to_tag,                   desc: "The last tag to marking"
    option :label,                    desc: "Label to be added to the MergeRequest"
    option :log_level,                desc: LOG_LEVEL_DESCRIPTION, default: "info"
    def marking
      Dotenv.load(*GITLAB_ENV_FILES)

      from_tag  = option_or_env!(:from_tag)
      to_tag    = option_or_env!(:to_tag)
      label     = option_or_env(:label) || to_tag

      project = create_project

      project.merge_request_iids_between(from_tag, to_tag).each do |iid|
        mr = project.merge_request(iid)
        project.add_merge_request_label(mr, label) if mr
      end
      @logger.info "finish!"
    end

    private

      def option_or_env(name, default = nil)
        upper_name = name.to_s.upcase
        return options[name] if options[name] && !options[name].to_s.empty?
        return ENV[upper_name] if ENV[upper_name] && !ENV[upper_name].empty?

        default
      end

      def option_or_env!(name)
        value = option_or_env(name)
        return value if value

        puts "--#{name.to_s.tr("_", "-")} or #{name.to_s.upcase} is either required!"
        exit!
      end

      def create_project
        gitlab_api_endpoint      = option_or_env!(:gitlab_api_endpoint)
        gitlab_api_private_token = option_or_env!(:gitlab_api_private_token)
        gitlab_project_name      = option_or_env!(:gitlab_project_name)
        allow_tag_format         = option_or_env(:allow_tag_format, DEFAULT_VERSION_FORMAT)

        @logger = Logger.new(STDOUT)
        @logger.level = logger_level(option_or_env(:log_level))
        @logger.formatter = proc { |severity, datetime, _progname, message|
          "[#{datetime}] #{severity} #{message}\n"
        }

        Gitlab::Request.logger = @logger
        GitlabAwesomeRelease::Project.new(
          api_endpoint:     gitlab_api_endpoint,
          private_token:    gitlab_api_private_token,
          project_name:     gitlab_project_name,
          allow_tag_format: /#{allow_tag_format}/,
          logger:           @logger
        )
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
