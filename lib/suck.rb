require 'net/http'
require 'uri'

require 'rubygems'
require 'ick'
require 'activesupport'

module Suck
  VERSION = '1.0.0'
  
  class Call
    Ick::Let.belongs_to self
    Ick::Maybe.belongs_to self
    
    attr_accessor :method,
              :scheme,
              :host,
              :port,
              :path,
              :query,
              :data,
              :username,
              :password,
              :user_agent,
              :callback,
              :response
    
    @@user_agent = "Suck/#{Suck::VERSION}"
    @@logger = nil
    
    def self.log_to( path )
      require 'logger'
      @@logger = Logger.new( path )
    end
    
    def self.get( uri, options = {}, &callback )
      Call.new( :get, uri, options, &callback )
    end
    
    def self.put( uri, options = {}, &callback )
      Call.new( :put, uri, options, &callback )
    end
    
    def self.post( uri, options = {}, &callback )
      Call.new( :post, uri, options, &callback )
    end
    
    def self.delete( uri, options = {}, &callback )
      Call.new( :delete, uri, options, &callback )
    end
    
    # Create a new HTTP Call instance
    #
    # +method+ should be one of :get, :put, :post, or :delete
    # +uri+ should be the full URI including username & password if appropriate
    # +options+ a hash of options including
    # * :threaded - whether to make the call using a separate thread (default: false)
    # +callback+ an optional block that will be called with the Call object
    #
    def initialize( method, uri, options = {}, &callback )
      options.reverse_merge! :threaded => false, :logged => false
      
      @method = method
      @threaded = options[:threaded]
      @logged = options[:logged]
      @callback = callback
      @user_agent = nil
      
      let( URI.parse( uri ) ) do |parsed_uri|
        @scheme = parsed_uri.scheme
        @host = parsed_uri.host
        @port = parsed_uri.port
        @path = parsed_uri.path
        @query = parsed_uri.query
        @username = parsed_uri.user
        @password = parsed_uri.password
      end
      
      @data = nil
      @response = nil
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
      log { "Making #{@method} request to #{uri.to_s} with data: #{data ? data.keys.join(",") : "none"}" }
      @response = do_http( data )
      log { "Response was #{status_code}: #{status_message} (#{ok? ? "#{@response.content_length} bytes" : "failed"})" }
      if @callback
        log { "Invoking callback" }
        @callback.call( self ) 
      end
      @response
    end
    
    def do_http( data )
      request = http_request
      request['User-Agent'] = @user_agent || @@user_agent
      request.basic_auth( @username, @password ) if @username
      if @method == :post && data
        @data = data
        request.set_form_data( data )
      end
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
    
    def ok?
      @response && @response.kind_of?( Net::HTTPSuccess )
    end
    
    def error?
      !ok?
    end
    
    def raise_on_error
      maybe( @response ) { |response| raise Net::HTTPError.new( status_message, response ) unless ok? }
    end
    
    def status_code
      maybe( @response ) { |response| response.code }
    end
    
    def status_message
      maybe( @response ) { |response| response.message }
    end
    
    def uri
      URI::HTTP.build( :scheme => @scheme, :host => @host, :port => @port, :path => @path, :query => @query )
    end
    
    def log
      maybe( @@logger ) { |logger| logger.info( "#{object_id}: #{yield}" ) }
    end
    
  private
    def make_http_request
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