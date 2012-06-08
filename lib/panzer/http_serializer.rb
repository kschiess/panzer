require 'rack/rewindable_input'
require 'net/http/server/parser'
require 'net/http/server/requests'
require 'net/http/server/responses'

module Panzer
  class HttpSerializer
    include ::Net::HTTP::Server::Requests
    include ::Net::HTTP::Server::Responses
    
    def initialize(host, port)
      @host, @port = host, port
    end
    
    def de(io)
      raw = read_request(io)
      
      parser = Net::HTTP::Server::Parser.new
      request = parser.parse(raw)
      
      normalize_request(request)
      env(request, io)
    rescue Parslet::ParseFailed => error
      puts "Bad request."
      puts error.cause.ascii_tree
    end
    
    def en(msg)
      stream = StringIO.new
      
      status, headers, body = *msg
      body.close unless body.closed?
      
      write_response(stream, status, headers, body)
      
      stream.string
    end
    
  private
    
    # Some of this is verbatim from Net/HTTP/Server - a rather inevitable
    # kind of reuse.
    #
    def env(request, stream)
      request_uri = request[:uri]
      
      remote_address = stream.remote_address
      
      env = {}.merge(DEFAULT_ENV)
      
      env['rack.input'] = ::Rack::RewindableInput.new(stream)
        
      env['rack.errors'] = $stdout
      
      env['REMOTE_ADDR'] = remote_address.ip_address
      env['REMOTE_PORT'] = remote_address.ip_port.to_s
      
      env['SERVER_NAME'] = @host
      env['SERVER_PORT'] = @port
      env['SERVER_PROTOCOL'] = "HTTP/#{request[:http_version]}"
      
      env['REQUEST_METHOD'] = request[:method].to_s
      env['PATH_INFO'] = request_uri.fetch(:path,'*').to_s
      env['QUERY_STRING'] = request_uri[:query_string].to_s
      
      request[:headers].each do |n,v|
        key = n.upcase.tr('-', '_')

        # All headers except these two need the HTTP_ prefix
        unless n.match(/Content-(Type|Length)/)
          key = "HTTP_#{key}"
        end
        
        env[key] = v
      end
      
      env
    end
    
    DEFAULT_ENV = {
      'rack.version' => ::Rack::VERSION,
      'rack.errors' => $stderr,
      'rack.multithread' => false,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'rack.url_scheme' => 'http',

      'SERVER_SOFTWARE' => "Panzer/0.1.0 (Ruby/#{RUBY_VERSION}/#{RUBY_RELEASE_DATE})",
      'SCRIPT_NAME' => ''
    }
  end
end