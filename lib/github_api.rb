# frozen_string_literal: true

require 'http'
require_relative 'project'
require_relative 'contributor'

module CodePraise
  # Client Library for Github Web API
  class GithubApi
    REPOS_PATH = 'https://api.github.com/repos/'

    def initialize(token)
      @gh_token = token
    end

    def project(username, project_name)
      project_response = Request.new(@gh_token)
                                .get(repo_url(username, project_name)).parse
      Project.new(project_response, self)
    end

    def contributors(contributors_url)
      contributors_data = Request.new(@gh_token)
                                 .get(contributors_url).parse
      contributors_data.map { |account_data| Contributor.new(account_data) }
    end

    private

    def repo_url(username, project_name)
      REPOS_PATH + [username, project_name].join('/')
    end

    # Sends out HTTP requests to Github
    class Request
      def initialize(token)
        @token = token
      end

      def get(url)
        http_response = HTTP.headers(
          'Accept' => 'application/vnd.github.v3+json',
          'Authorization' => "token #{@token}"
        ).get(url)

        Response.new(http_response).tap do |response|
          raise(response.error) unless response.successful?
        end
      end
    end

    # Decorates HTTP responses from Github with success/error reporting
    class Response < SimpleDelegator
      Unauthorized = Class.new(StandardError)
      NotFound = Class.new(StandardError)

      HTTP_ERROR = {
        401 => Unauthorized,
        404 => NotFound
      }.freeze

      def successful?
        HTTP_ERROR.keys.none?(code)
      end

      def error
        HTTP_ERROR[code]
      end
    end
  end
end
