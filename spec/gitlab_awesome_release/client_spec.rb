describe GitlabAwesomeRelease::Client do
  # let(:client) do
  #   GitlabAwesomeRelease::Client.new(
  #     api_endpoint:  ENV["GITLAB_API_ENDPOINT"],
  #     private_token: ENV["GITLAB_API_PRIVATE_TOKEN"],
  #     project_name:  ENV["GITLAB_PROJECT_NAME"],
  #   )
  # end

  let(:client) do
    GitlabAwesomeRelease::Client.new(
      api_endpoint:  api_endpoint,
      private_token: private_token,
      project_name:  project_name,
    )
  end

  let(:api_endpoint)         { "http://example.com/api/v3" }
  let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
  let(:project_name)         { "group/name" }
  let(:escaped_project_name) { "group%2Fname" }

  describe "#latest_tag" do
    subject { client.latest_tag }

    before do
      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/repository/tags?page=1&per_page=100").
        with(headers: {"Accept" => "application/json", "Private-Token" => private_token}).
        to_return(status: 200, body: read_stub("repository_tags.json"), headers: {})
    end

    it { should eq "v0.0.3" }
  end
end
