# frozen_string_literal: true

require 'http'

module CodePraise
  # Data structures for Github entities
  Project = Struct.new(:size, :git_url, :owner, :contributors)
  Contributor = Struct.new(:username, :email)

  # Library for Github Web API
  class GithubApi
    API_PROJECT_ROOT = 'https://api.github.com/repos'

    module Errors
      class NotFound < StandardError; end
      class Unauthorized < StandardError; end
    end

    HTTP_ERROR = {
      401 => Errors::Unauthorized,
      404 => Errors::NotFound
    }.freeze

    def initialize(token)
      @gh_token = token
    end

    def project(username, project_name)
      project_req_url = gh_api_path([username, project_name].join('/'))
      project_data = call_gh_url(project_req_url).parse

      Project.new(
        size: project_data['size'],
        git_url: project_data['git_url'],
        owner: Contributor.new(
          username: project_data['owner']['login'],
          email: project_data['owner']['email']
        ),
        contributors: contributors(project_data['contributors_url'])
      )
    end

    def contributors(contributors_url)
      contributors_data = call_gh_url(contributors_url).parse
      contributors_data.map do |account_data|
        Contributor.new(
          username: account_data['login'],
          email: account_data['email']
        )
      end
    end

    private

    def gh_api_path(path)
      "#{API_PROJECT_ROOT}/#{path}"
    end

    def call_gh_url(url)
      result =
        HTTP.headers('Accept' => 'application/vnd.github.v3+json',
                     'Authorization' => "token #{@gh_token}")
            .get(url)

      successful?(result) ? result : raise(HTTP_ERROR[result.code])
    end

    def successful?(result)
      !HTTP_ERROR.keys.include?(result.code)
    end
  end
end
