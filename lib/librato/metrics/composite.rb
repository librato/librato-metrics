module Librato::Metrics
  class Composite
    attr_accessor :client, :compose, :resolution, :start_time, :end_time
    attr_accessor :last_response

    # @option options [Client] :client Client instance used to connect to Metrics
    def initialize(options={})
      @client = options[:client] || Librato::Metrics.client
      @compose = options[:compose]
      @start_time = options[:start_time]
      @end_time = options[:end_time]
      @resolution = options[:resolution]
    end

    def composite_params
      {
        compose: compose,
        start_time: start_time,
        end_time: end_time,
        resolution: resolution
      }
    end

    def to_s
      composite_params
    end

    def get
      path = 'metrics'
      self.last_response = client.connection.get(path, composite_params)
      if last_response.success?
        parse_body
      else
        last_response
      end
    end

    def parse_body
      SmartJSON.read(last_response.body)
    end

    def measurements
      parse_body['measurements']
    end

    def sources
      measurements.map {|m| m['source']['name'] if m['source']}
    end

    def source_display_names
      measurements.map {|m| m['source']['display_name'] if m['source']}
    end

    def values
      get_series_values 'value'
    end

    def measure_times
      get_series_values 'measure_time'
    end

    # Sources mapped to measurement values
    # e.g.
    # {
    #   "austin" => [{1414800900=>66.76}, {1414801800=>65.49}, {1414802700=>64.34}],
    #   "seoul"  => [{1414800900=>56.61}, {1414801800=>57.28}, {1414802700=>57.95}],
    #   "sf"     => [{1414800900=>60.43}, {1414801800=>60.125}, {1414802700=>59.65}],
    # }
    def results
      {}.tap do |result|
        measurements.each do |meas|
          source = meas['source'] ? meas['source']['name'] : 'unassigned'
          result[source] = meas['series'].map {|s| {s['measure_time'] => s['value']}}
        end
      end
    end

    # private
    def get_series_values(key)
      result = measurements.map do |meas|
        meas['series'].map {|m| m[key]}
      end
      result.size == 1 ? result.flatten : result
    end


  end
end
