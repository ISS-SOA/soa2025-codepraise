# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project data to the CodePraise API
    class AddProject
      include Dry::Transaction

      step :validate_input
      step :request_project
      step :reify_project

      private

      def validate_input(input)
        if input.success?
          owner_name, project_name = input[:remote_url].split('/')[-2..]
          Success(owner_name:, project_name:)
        else
          Failure(input.errors.first.text)
        end
      end

      def request_project(input)
        result = Gateway::Api.new(CodePraise::App.config)
          .add_project(input[:owner_name], input[:project_name])

        if result.success?
          Success(result.payload)
        else
          Representer::HttpResponse
            .new(OpenStruct.new)
            .from_json(result.payload)
            .then { |error| Failure(error.message) }
        end
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
        Failure('Cannot process the project — please check with admins')
      end

      def reify_project(project_json)
        Representer::Project.new(OpenStruct.new)
          .from_json(project_json)
          .then { |project| Success(project) }
      rescue StandardError
        Failure('Error in the project -- please try again')
      end
    end
  end
end
