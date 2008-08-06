require 'net/http'
require 'uri'

require 'rubygems'

class Hash
  # Allows for reverse merging where its the keys in the calling hash that wins over those in the <tt>other_hash</tt>.
  # This is particularly useful for initializing an incoming option hash with default values:
  #
  #   def setup(options = {})
  #     options.reverse_merge! :size => 25, :velocity => 10
  #   end
  #
  # The default <tt>:size</tt> and <tt>:velocity</tt> is only set if the +options+ passed in doesn't already have those keys set.
  
  # Performs the opposite of merge, with the keys and values from the first hash taking precedence over the second.
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end unless method_defined?( :reverse_merge )
  
  # Performs the opposite of merge, with the keys and values from the first hash taking precedence over the second.
  # Modifies the receiver in place.
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end unless method_defined?( :reverse_merge! )
end

module Suck
  VERSION = '1.0.1'
  
  class Call
    
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
    
    @@mocker = nil
    
    def self.mock_mode( &callback )
      @@mocker = callback
    end
    
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
      
      parsed_uri = URI.parse( uri )
      @scheme = parsed_uri.scheme
      @host = parsed_uri.host
      @port = parsed_uri.port
      @path = parsed_uri.path
      @query = parsed_uri.query
      @username = parsed_uri.user
      @password = parsed_uri.password
      
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
      log { "Making #{@method} request to #{uri.to_s} with data: #{loggable_data(data)}" }
      @response = do_http( data )
      log { "Response was #{status_code}: #{status_message} ( #{ok? ? "#{@response.content_length} bytes: #{loggable_value( @response.body.to_s )}" : "failed"} )" }
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
      raise Net::HTTPError.new( status_message, response ) unless ok?
    end
    
    def status_code
      @response && @response.code.to_i
    end
    
    def status_message
      @response && @response.message
    end
    
    def uri
      URI::HTTP.build( :scheme => @scheme, :host => @host, :port => @port, :path => @path, :query => @query )
    end
    
    def log
      @@logger && @@logger.info( "#{object_id}: #{yield}" )
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
    
    def loggable_data( data )
      if data
        data.map { |key,value| "#{key.to_s}=#{loggable_value( value.to_s )}" }.join( "," )
      else
        "none"
      end
    end
    
    def loggable_value( str, cutoff = 512 )
      if str.length > cutoff
        "#{str.slice(0,cutoff)}..."
      else
        str
      end
    end
    
  end
  
end