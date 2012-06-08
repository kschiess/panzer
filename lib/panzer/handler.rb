require 'cod'
require 'rack'

module Panzer
  module Rack
    class Handler
      def self.run(app, options={})
        new(app, options).run
      end
      
      def initialize(app, options)
        host = options[:Host] || 'localhost'
        port = options[:Port] || 3000
        @url = "#{host}:#{port}"
        @app = app
        @serializer = HttpSerializer.new(host, port)
        
        puts "Panzer located at #{@url}."
      end
      
      def run
        http = Cod.tcp_server(@url, @serializer)
        
        loop do
          request, http_answer = http.get_ext

          answer = @app.call(request)

          http_answer.put answer
          http_answer.close
        end
      end
    end
    
    ::Rack::Handler.register 'panzer', 'Panzer::Rack::Handler'
  end
end