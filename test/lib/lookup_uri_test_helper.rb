module LookupURITestHelper
  class ResponseStream
    def initialize(body)
      @chunks = body
    end

    def readpartial
      @chunks.shift
    end
  end

  class ResponseFetcher
    attr_accessor :requests
    attr_accessor :responses

    def initialize(responses)
      self.requests = []
      self.responses = responses.each_with_object({}) do |(k, v), o|
        o[HTTP::URI.parse k] = v
      end
    end

    def perform_stub
      this = self
      lambda do |request, options|
        this.requests << request
        this.responses.fetch(request.uri)
      end
    end
  end

  def redirect_response(location, status = 302)
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :headers => {"Location" => location},
      :body    => HTTP::Response::Body.new(ResponseStream.new([""]), encoding: Encoding::UTF_8)
    )
  end

  def simple_response(body, status = 200)
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :body    => HTTP::Response::Body.new(ResponseStream.new([body]), encoding: Encoding::UTF_8)
    )
  end

  def chunked_response(body, status = 200)
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :body    => HTTP::Response::Body.new(ResponseStream.new(body), encoding: Encoding::UTF_8)
    )
  end
end
