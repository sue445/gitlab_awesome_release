describe GitlabAwesomeRelease::CLI do
  before do
    # Ignore assert_merge_request_iid because stub always return same response
    allow_any_instance_of(GitlabAwesomeRelease::Project).to receive(:assert_merge_request_iid)
  end

  describe "#create_note" do
    subject do
      GitlabAwesomeRelease::CLI.new.invoke(
        :create_note,
        [],
        {
          filename: filename,
          from_tag: from_tag,
          to_tag:   to_tag,
          gitlab_api_endpoint:      api_endpoint,
          gitlab_api_private_token: private_token,
          gitlab_project_name:      project_name,
          log_level: log_level,
        }
      )
    end

    let(:filename) { nil }
    let(:from_tag) { nil }
    let(:to_tag)   { nil }
    let(:api_endpoint)         { "http://example.com/api/v4" }
    let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
    let(:project_name)         { "group/name" }
    let(:escaped_project_name) { "group%2Fname" }
    let(:web_url)              { "http://example.com/#{project_name}" }
    let(:log_level)            { "error" }

    before do
      # ignore dotenv
      allow(Dotenv).to receive(:load)

      allow_any_instance_of(GitlabAwesomeRelease::Project).to receive(:web_url) { web_url }

      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/repository/tags?page=1&per_page=100").
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_tags.json"), headers: {})

      stub_request(:get, %r{#{api_endpoint}/projects/#{escaped_project_name}/repository/compare}).
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_compare.json"), headers: {})

      stub_request(:get, %r{#{api_endpoint}/projects/#{escaped_project_name}/merge_requests}).
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("merge_requests_with_iid.json"), headers: {})
    end

    context "When both 'from_tag' and 'to_tag' are empty" do
      let(:from_tag) { nil }
      let(:to_tag)   { nil }

      it "should be successful" do
        subject
      end
    end

    context "When both 'from_tag' and 'to_tag' have value" do
      let(:from_tag) { "v0.0.1" }
      let(:to_tag)   { "v0.0.2" }

      it "should be successful" do
        subject
      end
    end

    context "When exists filename" do
      include_context "uses temp dir"

      let(:filename) { temp_dir_path.join("CHANGELOG.md") }

      it "should be create CHANGELOG.md" do
        subject
        expect(filename.size).to be > 0
      end
    end
  end

  describe "#marking" do
    subject do
      GitlabAwesomeRelease::CLI.new.invoke(
        :marking,
        [],
        {
          from_tag: from_tag,
          to_tag:   to_tag,
          label:    label,
          gitlab_api_endpoint:      api_endpoint,
          gitlab_api_private_token: private_token,
          gitlab_project_name:      project_name,
          log_level: log_level,
        }
      )
    end

    let(:from_tag) { "v0.0.1" }
    let(:to_tag)   { "v0.0.2" }
    let(:label)    { "ver0.0.2" }
    let(:api_endpoint)         { "http://example.com/api/v4" }
    let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
    let(:project_name)         { "group/name" }
    let(:escaped_project_name) { "group%2Fname" }
    let(:log_level)            { "error" }

    before do
      stub_request(:get, %r{#{api_endpoint}/projects/#{escaped_project_name}/repository/compare}).
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_compare.json"), headers: {})

      stub_request(:get, %r{#{api_endpoint}/projects/#{escaped_project_name}/merge_requests}).
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("merge_requests_with_iid.json"), headers: {})

      stub_request(:put, %r{#{api_endpoint}/projects/#{escaped_project_name}/merge_requests/[0-9]+}).
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("merge_request.json"), headers: {})
    end

    it "should be successful" do
      subject
    end
  end
end
