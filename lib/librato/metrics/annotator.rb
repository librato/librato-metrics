module Librato::Metrics

  # manages writing and reading annotation streams for a
  # given client connection
  class Annotator

    def initialize(options={})
      @client = options[:client] || Librato::Metrics.client
    end

    # Creates a new annotation on the annotation stream
    #
    # @example Simple annotation
    #   annotator.add :deployments, 'deployed v45'
    #
    # @example Annotation with start and end times
    #   annotator.add :deployments, 'deployed v56', :start_time => start,
    #                 :end_time => end
    #
    # @example Annotation with a specific source
    #   annotator.add :deployments, 'deployed v60', :source => 'app12'
    #
    def add(stream, title, options={})
      options[:title] = title
      payload = SmartJSON.write(options)
      # expects 200
      connection.post("annotations/#{stream}", payload)
    end

    def client
      @client
    end

    def connection
      client.connection
    end

    # Delete one or more annotation streams
    #
    # @example Delete 'deployment' annotation stream
    #  annotator.delete :deployment
    #
    def delete(stream)
      connection.delete do |request|
        request.url connection.build_url("annotations/#{stream}")
      end
      # expects 204, middleware will raise exception otherwise
      true
    end

    # Get a list of annotation events on a given annotation stream
    #
    # @example See properties of the 'deployments' annotation stream
    #   annotator.fetch :deployments
    #
    # @example Get events on 'deployments' between start and end times
    #   annotator.fetch :deployments, :start_time => start, :end_time => end
    #
    # @example Source-limited listing
    #   annotator.fetch :deployments, :sources => ['foo','bar','baz']
    #
    def fetch(stream, options={})
      url = connection.build_url("annotations/#{stream}", options)
      response = connection.get(url)
      SmartJSON.read(response.body)
    end

    # List currently existing annotation streams
    #
    # @example List all annotation streams
    #   streams = annotator.list
    #
    # @example List annotator streams with 'deploy' in the name
    #   deploy_streams = annotator.list :name => 'deploy'
    #
    def list(options={})
      response = connection.get("annotations", options)
      SmartJSON.read(response.body)
    end

  end

end