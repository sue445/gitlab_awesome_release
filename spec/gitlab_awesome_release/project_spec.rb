describe GitlabAwesomeRelease::Project do
  let(:project) do
    GitlabAwesomeRelease::Project.new(
      api_endpoint:     api_endpoint,
      private_token:    private_token,
      project_name:     project_name,
      allow_tag_format: allow_tag_format,
      logger:           logger
    )
  end

  let(:api_endpoint)         { "http://example.com/api/v4" }
  let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
  let(:project_name)         { "group/name" }
  let(:escaped_project_name) { "group%2Fname" }
  let(:web_url)              { "http://example.com/#{project_name}" }
  let(:allow_tag_format)     { /^v?[\d.]+/ }
  let(:logger) do
    _logger = Logger.new(STDOUT)
    _logger.level = Logger::ERROR
    _logger
  end

  before do
    allow(project).to receive(:web_url) { web_url }
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

    it { should eq "* Add yes [!5](#{web_url}/merge_requests/5) *@sue445*" }
  end

  describe "#generate_release_note" do
    subject { project.generate_release_note(from, to, title: title) }

    before do
      allow(project).to receive(:merge_requests_summary_between) { summary }
    end

    let(:from)  { "v0.0.2" }
    let(:to)    { "v0.0.3" }

    let(:summary) do
      <<-EOS
* Add yes [!5](#{web_url}/merge_requests/5) *@sue445*
* Add gogo [!6](#{web_url}/merge_requests/6) *@sue445*
      EOS
    end

    context "When not specified title" do
      let(:title) { nil }

      let(:expected) do
        <<-EOS
## #{to}
[full changelog](#{web_url}/compare/#{from}...#{to})

* Add yes [!5](#{web_url}/merge_requests/5) *@sue445*
* Add gogo [!6](#{web_url}/merge_requests/6) *@sue445*
        EOS
      end

      it { should eq expected }
    end

    context "When specified title" do
      let(:title) { "Title" }

      let(:expected) do
        <<-EOS
## #{title}
[full changelog](#{web_url}/compare/#{from}...#{to})

* Add yes [!5](#{web_url}/merge_requests/5) *@sue445*
* Add gogo [!6](#{web_url}/merge_requests/6) *@sue445*
        EOS
      end

      it { should eq expected }
    end
  end

  describe "#generate_change_log" do
    subject { project.generate_change_log(oldest_tag, newest_tag) }

    let(:oldest_tag) { "v0.0.1" }
    let(:newest_tag) { "v0.0.3" }

    before do
      allow(project).to receive(:all_tag_names) { ["v0.0.1", "v0.0.2", "v0.0.3"] }

      allow(project).to receive(:generate_release_note).with("v0.0.1", "v0.0.2") do
        <<-EOS
## v0.0.2
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.1...v0.0.2)

* Add splash_star [!4](https://gitlab.com/sue445/gitlab_example/merge_requests/4) *@sue445*
        EOS
      end

      allow(project).to receive(:generate_release_note).with("v0.0.2", "v0.0.3") do
        <<-EOS
## v0.0.3
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.2...v0.0.3)

* Add yes [!5](https://gitlab.com/sue445/gitlab_example/merge_requests/5) *@sue445*
* Add gogo [!6](https://gitlab.com/sue445/gitlab_example/merge_requests/6) *@sue445*
        EOS
      end

      allow(project).to receive(:generate_release_note).with("v0.0.3", "HEAD", { title: "Unreleased" }) do
        <<-EOS
## Unreleased
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.3...HEAD)
        EOS
      end
    end

    it "should generate changelog between oldest_tag and newest_tag" do
      should eq <<-EOS
## Unreleased
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.3...HEAD)

## v0.0.3
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.2...v0.0.3)

* Add yes [!5](https://gitlab.com/sue445/gitlab_example/merge_requests/5) *@sue445*
* Add gogo [!6](https://gitlab.com/sue445/gitlab_example/merge_requests/6) *@sue445*

## v0.0.2
[full changelog](https://gitlab.com/sue445/gitlab_example/compare/v0.0.1...v0.0.2)

* Add splash_star [!4](https://gitlab.com/sue445/gitlab_example/merge_requests/4) *@sue445*

## v0.0.1

*This Change Log was automatically generated by [gitlab_awesome_release](https://gitlab.com/sue445/gitlab_awesome_release)*
      EOS
    end
  end

  describe "#release_tag_names" do
    subject { project.release_tag_names }

    before do
      allow(project).to receive(:all_tag_names) { %w(v0.0.1 0.0.2 tmp v0.0.3.beta1 v0.0.3) }
    end

    let(:allow_tag_format) { /^v?[\d.]+/ }

    it { should eq %w(v0.0.1 0.0.2 v0.0.3.beta1 v0.0.3) }
  end
end
