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
    # @example Annotation with a description
    #   annotator.add :deployments, 'deployed v61',
    #                 :description => '9b562b2: shipped new feature foo!'
    #
    def add(stream, title, options={})
      options[:title] = title
      if options[:start_time]
        options[:start_time] = options[:start_time].to_i
      end
      if options[:end_time]
        options[:end_time] = options[:end_time].to_i
      end
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

    # Delete an annotation streams
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

    # Delete an event from a given annotation stream
    #
    # @example Delete event with id 42 from 'deployment'
    #   annotator.delete_event :deployment, 42
    #
    def delete_event(stream, id)
      connection.delete do |request|
        request.url connection.build_url("annotations/#{stream}/#{id}")
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
    #   annotator.fetch :deployments, :sources => ['foo','bar','baz'],
    #                   :start_time => start, :end_time => end
    #
    def fetch(stream, options={})
      response = connection.get("annotations/#{stream}", options)
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