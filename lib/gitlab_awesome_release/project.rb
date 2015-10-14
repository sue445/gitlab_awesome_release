module GitlabAwesomeRelease
  require "cgi"
  require "gitlab_awesome_release/array_within_ext"

  class Project
    using GitlabAwesomeRelease::ArrayWithinExt

    PER_PAGE = 100

    # @param api_endpoint     [String]
    # @param private_token    [String]
    # @param project_name     [String]
    # @param allow_tag_format [Regexp]
    def initialize(api_endpoint:, private_token:, project_name:, allow_tag_format:, logger:)
      Gitlab.configure do |config|
        config.endpoint      = api_endpoint
        config.private_token = private_token
      end
      @project_name = project_name
      @allow_tag_format = allow_tag_format
      @logger = logger
    end

    def web_url
      @web_url ||= Gitlab.project(escaped_project_name).web_url
    end

    # all tag names order by author date
    # @return [Array<String>]
    def all_tag_names
      return @all_tag_names if @all_tag_names

      @logger.info "fetch git tags"
      repo_tags =
        with_paging do |params|
          Gitlab.repo_tags(escaped_project_name, params)
        end
      @all_tag_names = repo_tags.sort_by{ |tag| tag.commit.authored_date }.map(&:name)
    end

    # @return [Array<String>]
    def release_tag_names
      all_tag_names.find_all { |tag| tag =~ @allow_tag_format }
    end

    # @param oldest_tag [String]
    # @param newest_tag [String]
    # @return [String]
    def generate_change_log(oldest_tag, newest_tag)
      release_notes = []
      release_tag_names.within(oldest_tag, newest_tag).each_cons(2) do |from, to|
        release_notes << generate_release_note(from, to)
      end
      release_notes << generate_release_note(newest_tag, "HEAD", title: "Unreleased") if newest_tag == all_tag_names.last

      release_notes.reverse.each_with_object("") do |release_note, str|
        str << release_note
        str << "\n"
      end
    end

    # generate release note between from...to
    # @param from  [String]
    # @param to    [String]
    # @param title [String]
    # @return [String]
    def generate_release_note(from, to, title: nil)
      @logger.info "generate release note (#{from}...#{to})"

      title ||= to
      summary = merge_requests_summary_between(from, to)

      header = <<-MARKDOWN.strip_heredoc
        ## #{title}
        [full changelog](#{web_url}/compare/#{from}...#{to})

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
      mr = merge_request(iid)
      return nil unless mr

      mr_url = "#{web_url}/merge_requests/#{iid}"
      "* #{mr.title} [!#{iid}](#{mr_url}) *@#{mr.author.username}*"
    end

    # find MergeRequest with iid
    def merge_request(iid)
      mr = Gitlab.merge_requests(escaped_project_name, iid: iid).first
      assert_merge_request_iid(mr, iid) if mr
      mr
    end

    def add_merge_request_label(mr, label)
      labels = mr.labels
      labels << label

      Gitlab.update_merge_request(escaped_project_name, mr.id, labels: labels.uniq.join(","))
      @logger.info "Add [#{label}] to !#{mr.iid}"
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

    def assert_merge_request_iid(mr, iid)
      # NOTE: MR is found, but server is old GitLab?
      raise "MergeRequest iid does not match (expected #{iid}, but #{mr.iid})" unless iid == mr.iid
    end
  end
end
