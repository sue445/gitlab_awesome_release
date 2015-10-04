# use real GitLab API (don't use mock)
shared_context :use_real_gitlab do
  let(:client) do
    GitlabAwesomeRelease::Client.new(
      api_endpoint:  ENV["GITLAB_API_ENDPOINT"],
      private_token: ENV["GITLAB_API_PRIVATE_TOKEN"],
      project_name:  ENV["GITLAB_PROJECT_NAME"],
    )
  end

  before do
    WebMock.allow_net_connect!
  end
end
