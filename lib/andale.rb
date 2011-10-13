require "spdy"
require "eventmachine"

# Andale, a simple SPDY framework
class Andale < EM::Connection
  VERSION = "0.0.1"

  # Aliases
  SynReply  = SPDY::Protocol::Control::SynReply
  DataFrame = SPDY::Protocol::Data::Frame

  def post_init
    # Create the SPDY parser and add bindings
    @parser = SPDY::Parser.new

    @parser.on_headers_complete do |stream_id, assoc_stream, priority, headers|
      # TODO assoc_stream and priority
      request  = Andale::Request.new self, stream_id, headers
      response = Andale::Stream.new  self, stream_id

      serve request, response
    end

    start_tls
  end

  def receive_data data
    # Feed received data to the parser, which in turn triggers the
    # proper events.
    #
    # See post_init for binded event handlers.
    @parser << data
  end

  # Wraps a SPDY reply by sending the headers packet and then the data
  # packet.
  def reply stream_id, headers = nil
    raise ArgumentError if headers.nil? unless block_given?

    unless headers.nil?
      syn_reply = SynReply.new :zlib_session => @parser.zlib_session

      data = { :stream_id => stream_id, :headers => headers }
      send_data syn_reply.create(data).to_binary_s
    end

    if block_given?
      data = yield
      send_data DataFrame.new.create(:stream_id => stream_id, :data => data).to_binary_s
    end
  end

  # Basic SPDY stream class
  #
  # Handles sending data through the stream and stream finalization.
  class Stream
    # This constant flag should be in SPDY!
    DATA_FIN = 1

    attr :stream_id, :connection

    def initialize connection, stream_id
      @connection = connection
      @stream_id  = stream_id
    end

    # Finalize stream
    #
    # Sends the proper control packets to tell the other side that
    # this stream won't send any further data.
    def fin!
      fin  = DataFrame.new
      data = fin.create(:stream_id => @stream_id, :flags => DATA_FIN)
      @connection.send_data data.to_binary_s
    end

    # Send data through the stream
    #
    # Headers are sent in a separated packet, and are the typical HTTP
    # headers we're used to deal with.
    #
    # headers - a Hash of HTTP headers
    # data    - a binary string of data
    def send headers, data
      # Always use HTTP/1.1
      headers["version"] = "HTTP/1.1"

      @connection.reply(@stream_id, headers) { data }
    end
  end

  # A wrapper on Andale::Stream to represent a SPDY response object
  class Response < Stream
  end

  # A wrapper on Andale::Stream to represent a SPDY request.
  # It extends Andale::Stream adding request specific methods.
  class Request < Stream
    attr :headers

    def initialize connection, stream_id, headers
      super connection, stream_id

      raise ArgumentError if headers.nil?

      @headers = headers
    end

    # Returns the URL that was requested
    def url
      @headers["url"]
    end

    # Returns the request method
    def method
      @headers["method"].upcase
    end

    # Useful aliases
    def get?     ; "GET"     == method ; end
    def post?    ; "POST"    == method ; end
    def options? ; "OPTIONS" == method ; end
    def put?     ; "PUT"     == method ; end
    def delete?  ; "DELETE"  == method ; end
    def head?    ; "HEAD"    == method ; end
  end

  # This method should be overriden by classes implementing Andale
  # SPDY servers.
  def serve request, response
    puts "#{Time.now} - #{request.method} #{request.url}"

    response.send({ "status" => "200 OK", "Content-Type" => "text/plain" }, "Hello, World!")
    response.fin!
  end
end
