class Librato::Space < OpenStruct
  class << self
    include Librato::Utils

    def find(id)
      new safe_parse(show_response(id))
    end

    def find_by_name(name)
      all.detect { |space| space.name == name }
    end

    def all
      safe_parse(index_response).fetch('spaces').map { |space| new space }
    end

    private

    def index_response
      client(SPACES_URL).run.response_body
    end

    def show_response(id)
      client("#{SPACES_URL}/#{id}").run.response_body
    end
  end
end
