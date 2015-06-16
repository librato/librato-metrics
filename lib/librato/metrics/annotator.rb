module Librato::Metrics

  # Read & write annotation streams for a given client connection.
  class Annotator

    # @option options [Client] :client Client instance used to connect to Metrics
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
    #                 :end_time => end_time
    #
    # @example Annotation with a specific source
    #   annotator.add :deployments, 'deployed v60', :source => 'app12'
    #
    # @example Annotation with a description
    #   annotator.add :deployments, 'deployed v61',
    #                 :description => '9b562b2: shipped new feature foo!'
    #
    # @example Annotate with automatic start and end times
    #   annotator.add(:deployments, 'deployed v62') do
    #     # do work..
    #   end
    #
    def add(stream, title, options={})
      options[:title] = title
      options[:start_time] = (options[:start_time] || Time.now).to_i
      if options[:end_time]
        options[:end_time] = options[:end_time].to_i
      end
      payload = SmartJSON.write(options)
      response = connection.post("annotations/#{stream}", payload)
      # will raise exception if not 200 OK
      event = SmartJSON.read(response.body)
      if block_given?
        yield
        update_event stream, event['id'], :end_time => Time.now.to_i
        # need to get updated representation
        event = fetch_event stream, event['id']
      end
      event
    end

    # client instance used by this object
    def client
      @client
    end

    # Delete an annotation stream
    #
    # @example Delete the 'deployment' annotation stream
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
    #   annotator.fetch :deployments, :start_time => start,
    #                   :end_time => end_time
    #
    # @example Source-limited listing
    #   annotator.fetch :deployments, :sources => ['foo','bar','baz'],
    #                   :start_time => start, :end_time => end_time
    #
    def fetch(stream, options={})
      response = connection.get("annotations/#{stream}", options)
      SmartJSON.read(response.body)
    end

    # Get properties for a given annotation stream event
    #
    # @example Get event
    #   annotator.fetch :deployments, 23
    #
    def fetch_event(stream, id)
      response = connection.get("annotations/#{stream}/#{id}")
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

    # Update an event's properties
    #
    # @example Set an end time for a previously submitted event
    #   annotator.update_event 'deploys', 'v24', :end_time => end_time
    #
    def update_event(stream, id, options={})
      url = "annotations/#{stream}/#{id}"
      connection.put do |request|
        request.url connection.build_url(url)
        request.body = SmartJSON.write(options)
      end
      # expects 204 will raise exception otherwise
    end

    private

    def connection
      client.connection
    end

  end

end