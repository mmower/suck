require 'ick'
require 'uri'
require 'net/http'

module Suck
  
  class Call
    Ick::Let.belongs_to self
    
    attr_accessor :method, :scheme, :host, :port, :path, :query, :username, :password, :user_agent, :callback
    
    @@user_agent = "Suck/1.0"
    
    def initialize( method, uri, threaded = false, &callback )
      @method = method
      @threaded = threaded
      @callback = callback
      @user_agent = nil
      
      @uri = let( URI.parse( uri ) ) do |parsed_uri|
        @scheme = parsed_uri.scheme
        @host = parsed_uri.host
        @port = parsed_uri.port
        @path = parsed_uri.path
        @query = parsed_uri.query
        @username = parsed_uri.user
        @password = parsed_uri.password
      end
    end
    
    def invoke( data = nil )
      if @threaded
        invoke_threaded( data )
      else
        invoke_inline( data )
      end
    end
    
    def invoke_threaded( data )
      Thread.new do
        invoke_inline( data )
      end
    end
    
    def invoke_inline( data )
      response = do_http( data )
      @callback.call( response, self ) if @callback
      response
    end
    
    def do_http( data )
      request = http_request
      request['User-Agent'] = @user_agent || @@user_agent
      request.basic_auth( @username, @password ) if @username
      request.set_form_data( data ) if @method == :post && data
      make_request( request )
    end
    
    def make_request( request )
      Net::HTTP.start( @host, @port ) do |http|
        http.request( http_request )
      end
    end
    
    def http_request
      @request ||= make_http_request
    end
    
  private
    def make_http_request
      uri = URI::HTTP.build( :scheme => @scheme, :host => @host, :port => @port, :path => @path, :query => @query )
      
      case @method
      when :get
        req = Net::HTTP::Get.new( uri.request_uri )
      when :put
        req = Net::HTTP::Put.new( uri.request_uri )
      when :post
        req = Net::HTTP::Post.new( uri.request_uri )
      when :delete
        req = Net::HTTP::Delete.new( uri.request_uri )
      else
        raise "Unknown HTTP method '#{@method}' in Suck::API invocation!"
      end
    end
    
  end
  
end