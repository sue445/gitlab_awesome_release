module GitlabAwesomeRelease
  require "gitlab"
  require "cgi"
  require "active_support/all"

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

    def project_web_url
      @project_web_url ||= Gitlab.project(escaped_project_name).web_url
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

    # all tag name order by author date
    # @return [Array<String>]
    def all_tag_names
      repo_tags =
        with_paging do |params|
          Gitlab.repo_tags(escaped_project_name, params)
        end
      repo_tags.sort_by{ |tag| tag.commit.authored_date }.map(&:name)
    end

    # generate changelog between from...to
    # @param from [String]
    # @param to   [String]
    # @return [String]
    def create_release_note(from, to)
      summary = merge_requests_summary_between(from, to)

      header = <<-MARKDOWN.strip_heredoc
        ## #{to}
        [full changelog](#{project_web_url}/compare/#{from}...#{to})

      MARKDOWN

      header + summary
    end

    # find merge requests between from...to
    # @param from [String]
    # @param to   [String]
    # @return [Array<Integer>] MergeRequest iids
    def merge_request_iids_between(from, to)
      commits = Gitlab.repo_compare(escaped_project_name, from, to).commits
      commits.map do |commit|
        commit["message"] =~ /^Merge branch .*See merge request \!(\d+)$/m
        $1
      end.compact.map(&:to_i)
    end

    # @param iid [Integer] MergeRequest iid
    # @return [String] markdown text
    def merge_request_summary(iid)
      mr = Gitlab.merge_requests(escaped_project_name, iid: iid).first
      return nil unless mr

      mr_url = "#{project_web_url}/merge_requests/#{iid}"
      "* #{mr.title} [!#{iid}](#{mr_url}) *@#{mr.author.username}*"
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

    def merge_requests_summary_between(from, to)
      mr_iids = merge_request_iids_between(from, to)
      mr_iids.each_with_object("") do |iid, str|
        str << merge_request_summary(iid) + "\n"
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
