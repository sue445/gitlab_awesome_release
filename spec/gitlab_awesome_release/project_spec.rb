describe GitlabAwesomeRelease::Project do
  let(:project) do
    GitlabAwesomeRelease::Project.new(
      api_endpoint:  api_endpoint,
      private_token: private_token,
      project_name:  project_name,
    )
  end

  let(:api_endpoint)         { "http://example.com/api/v3" }
  let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
  let(:project_name)         { "group/name" }
  let(:escaped_project_name) { "group%2Fname" }
  let(:project_web_url)      { "http://example.com/#{project_name}" }

  before do
    allow(project).to receive(:project_web_url) { project_web_url }
  end

  describe "#all_tag_names" do
    subject { project.all_tag_names }

    before do
      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/repository/tags?page=1&per_page=100").
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_tags.json"), headers: {})
    end

    it { should eq ["v0.0.1", "v0.0.2", "v0.0.3"] }
  end

  describe "#merge_request_iids_between" do
    subject { project.merge_request_iids_between(from, to) }

    before do
      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/repository/compare?from=#{from}&to=#{to}").
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_compare.json"), headers: {})
    end

    let(:from) { "v0.0.2" }
    let(:to)   { "v0.0.3" }

    it { should contain_exactly(5, 6) }
  end

  describe "#merge_request_summary" do
    subject { project.merge_request_summary(iid) }

    before do
      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/merge_requests?iid=#{iid}").
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("merge_requests_with_iid.json"), headers: {})
    end

    let(:iid) { 5 }

    it { should eq "* Add yes [!5](#{project_web_url}/merge_requests/5) *@sue445*" }
  end

  describe "#create_release_note" do
    subject { project.create_release_note(from, to) }

    before do
      allow(project).to receive(:merge_requests_summary_between){ summary }
    end

    let(:from) { "v0.0.2" }
    let(:to)   { "v0.0.3" }
    let(:summary) do
      <<-EOS.strip_heredoc
        * Add yes [!5](#{project_web_url}/merge_requests/5) *@sue445*
        * Add gogo [!6](#{project_web_url}/merge_requests/6) *@sue445*
      EOS
    end

    let(:expected) do
      <<-EOS.strip_heredoc
        ## #{to}
        [full changelog](#{project_web_url}/compare/#{from}...#{to})

        * Add yes [!5](#{project_web_url}/merge_requests/5) *@sue445*
        * Add gogo [!6](#{project_web_url}/merge_requests/6) *@sue445*
      EOS
    end

    it { should eq expected }
  end
end
