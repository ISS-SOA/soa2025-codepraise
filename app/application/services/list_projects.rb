# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Retrieves array of all listed project entities
    class ListProjects
      include Dry::Transaction

      step :get_api_list
      step :reify_list

      private

      def get_api_list(projects_list)
        result = Gateway::Api.new(CodePraise::App.config)
          .projects_list(projects_list)

          if result.success?
            Success(result.payload)
          else
            Representer::HttpResponse
            .new(OpenStruct.new)
            .from_json(result.payload)
            .then { |error| Failure(error.message) }
          end
      rescue StandardError
        Failure('Could not access our API')
      end

      def reify_list(projects_json)
        Representer::ProjectsList.new(OpenStruct.new)
          .from_json(projects_json)
          .then { |projects| Success(projects) }
      rescue StandardError
        Failure('Could not parse response from API')
      end
    end
  end
end
