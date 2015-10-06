require "thor"
require "gitlab_awesome_release"
require "dotenv"

module GitlabAwesomeRelease
  class CLI < Thor
    desc "version", "Show gitlab_awesome_release version"
    def version
      puts GitlabAwesomeRelease::VERSION
    end

    desc "generate", "generate changelog"
    option :filename
    option :from
    option :to
    option :gitlab_api_endpoint
    option :gitlab_api_private_token
    option :gitlab_project_name
    def create_note
      Dotenv.load

      gitlab_api_endpoint      = option_or_env!(:gitlab_api_endpoint)
      gitlab_api_private_token = option_or_env!(:gitlab_api_private_token)
      gitlab_project_name      = option_or_env!(:gitlab_project_name)

      project = GitlabAwesomeRelease::Project.new(
        api_endpoint:  gitlab_api_endpoint,
        private_token: gitlab_api_private_token,
        project_name:  gitlab_project_name,
      )

      tag_names = project.all_tag_names
      oldest_tag = option_or_env(:from) || tag_names.first
      newest_tag = option_or_env(:to)   || tag_names.last

      raise "Unknown tag: #{oldest_tag}" unless tag_names.include?(oldest_tag)
      raise "Unknown tag: #{newest_tag}" unless tag_names.include?(newest_tag)

      oldest_index = tag_names.find_index(oldest_tag)
      newest_index = tag_names.find_index(newest_tag)

      release_notes = []
      tag_names[oldest_index..newest_index].each_cons(2) do |from, to|
        release_notes << project.create_release_note(from, to)
      end
      release_notes << project.create_release_note(newest_tag, "HEAD") if newest_tag == tag_names.last

      changelog = release_notes.reverse.each_with_object("") do |release_note, str|
        str << release_note
        str << "\n"
      end

      filename = option_or_env(:filename)
      if filename
        File.open(filename, "wb") do |f|
          f.write(changelog)
        end
        puts "Write #{filename}"
      else
        puts changelog
      end
    end

    private

    def option_or_env(name)
      upper_name = name.to_s.upcase
      options[name].presence || ENV[upper_name].presence
    end

    def option_or_env!(name)
      value = option_or_env(name)
      return value if value

      puts "--#{name.to_s.gsub("_", "-")} or #{name.to_s.upcase} is either required!"
      exit!
    end
  end
end
