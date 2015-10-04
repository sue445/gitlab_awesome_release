module GitlabAwesomeRelease
  require "gitlab"
  require "cgi"

  class Client
    PER_PAGE = 100

    # @param api_endpoint  [String]
    # @param private_token [String]
    # @param project_name  [String]
    def initialize(api_endpoint:, private_token:, project_name:)
      Gitlab.configure do |config|
        config.endpoint      = api_endpoint
        config.private_token = private_token
      end
      @project_name = project_name
    end

    # @return [String]
    def latest_tag
      repo_tags =
        with_paging do |params|
          Gitlab.repo_tags(escaped_project_name, params)
        end

      tag_names = repo_tags.map(&:name)
      tag_names.max_by { |tag| gem_version(tag) }
    end

    private

    def escaped_project_name
      CGI.escape(@project_name)
    end

    # @yield [params] paging block
    # @yieldparam params [Hash] paging params for GitLab API (page: current page, per_page)
    # @yieldreturn response in all pages
    def with_paging
      all_response = []
      page = 1
      loop do
        response = yield(page: page, per_page: PER_PAGE)
        all_response += response
        return all_response if response.size < PER_PAGE
        page += 1
      end
    end

    def gem_version(tag)
      version = tag.sub(/^v/, "").strip
      Gem::Version.create(version)
    rescue ArgumentError
      # ignore: Malformed version number string XXXXX
      Gem::Version.create("0.0.0")
    end
  end
end
