require File.join( File.dirname( __FILE__ ), '..', 'spec_helper' )

require 'suck'
require 'net/http'

module Suck
  
  describe Call, "User Agent" do
    
    before( :each ) do
      @call = Call.get( "http://test.com/resources?filter=new" )
    end
    
    it "should use default user agent" do
      @call.expects( :make_request ).with do |request|
        request[ 'User-Agent' ].should eql( "Suck/1.0.0" )
        true
      end
      @call.invoke
    end
    
    it "should use custom user agent" do
      @call.user_agent = "MySuck/1.0"
      @call.expects( :make_request ).with do |request|
        request['User-Agent'].should eql( 'MySuck/1.0' )
        true
      end
      @call.invoke
    end
  end
  
  describe Call, "inline GET" do
    
    before( :each ) do
      @call = Call.get( "http://test.com/resources?filter=new" )
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
      @fail = Net::HTTPResponse::CODE_TO_OBJ['500'].new( "HTTP/1.0", 500, "Server failed" )
    end
    
    it "should initialize" do
      @call.should_not be_nil
    end
    
    it "should use Net::HTTP::Get request" do
      @call.http_request.should be_an_instance_of( Net::HTTP::Get )
    end
    
    it "should make GET request" do
      @call.expects( :invoke_threaded ).never
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.invoke
    end
    
    it "should be ok?" do
      Net::HTTP.any_instance.expects( :start ).with( anything ).returns( @ok )
      @call.invoke
      @call.should be_ok
    end
    
    it "should not be ok?" do
      Net::HTTP.any_instance.expects( :start ).with( anything ).returns( @fail )
      @call.invoke
      @call.should_not be_ok
    end
  end
  
  describe Call, "inline GET with callback" do
    
    before( :each ) do
      @called_back = false
      @call = Call.get( "http://test.com/resources?filter=new" ) { |call|
        @called_back = true
      }
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
    end
    
    it "should invoke the callback" do
      @call.invoke
      @called_back.should be_true
    end
  end
  
  describe Call, "inline GET with authorization" do
    
    before( :each ) do
      @call = Call.get( "http://matt:abc123@test.com/resources?filter=new" )
    end
    
    it "should have username" do
      @call.username.should eql("matt")
    end
    
    it "should have password" do
      @call.password.should eql("abc123")
    end
    
    it "should set basic auth" do
      Net::HTTP.any_instance.expects( :request ).with() do |request|
        request["authorization"].should eql( 'Basic ' + ["matt:abc123"].pack('m').delete("\r\n") )
        true
      end
      @call.invoke
    end
  end
  
  describe Call, "threaded GET" do
    
    before( :each ) do
      @call = Call.get( "http://test.com/resources?filter=new", :threaded => true )
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should use threading" do
      @call.expects( :invoke_threaded ).once
      @call.invoke
    end
    
    it "should return Thread" do
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      o = @call.invoke
      o.should be_instance_of( Thread )
      o.join
    end
  end
  
  describe Call, "threaded GET with callback" do
    
    before( :each ) do
      @called_back = false
      @call = Call.get( "http://test.com/resources?filter=new", :threaded => true ) { |call|
        @called_back = true
      }
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should invoke the callback" do
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.invoke.join
      @called_back.should be_true
    end
  end
  
  describe Call, "inline PUT" do
    
    before( :each ) do
      @call = Call.put( "http://test.com/resource/1" )
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should initialize" do
      @call.should_not be_nil
    end
    
    it "should use Net::HTTP::Put request" do
      @call.http_request.should be_an_instance_of( Net::HTTP::Put )
    end
    
    it "should make PUT request" do
      @call.expects( :invoke_threaded ).never
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.invoke
    end
    
  end
  
  describe Call, "inline POST" do
    
    before( :each ) do
      @call = Call.post( "http://test.com/resources" )
      @form = {
        :login => 'matt',
        :name => 'Matt Mower',
        :email => 'self@mattmower.com'
      }
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should initialize" do
      @call.should_not be_nil
    end
    
    it "should use Net::HTTP::Post request" do
      @call.http_request.should be_an_instance_of( Net::HTTP::Post )
    end
    
    it "should make POST request" do
      @call.expects( :invoke_threaded ).never
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.invoke( @form )
    end
    
    it "should set Content-Type" do
      Net::HTTP.any_instance.expects( :request ).with do |request|
        request[ 'Content-Type' ].should eql( "application/x-www-form-urlencoded" )
        true
      end.returns( @ok )
      @call.invoke( @form )
    end
    
    it "should contain POST'd data" do
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.http_request.expects( :body= ).with( form_encode( @form ) )
      @call.invoke( @form )
    end
    
  end
  
  describe Call, "threaded POST" do
    
    before( :each ) do
      @call = Call.post( "http://test.com/resources", :threaded => true )
      @form = {
        :login => 'matt',
        :name => 'Matt Mower',
        :email => 'self@mattmower.com'
      }
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should use threading" do
      @call.expects( :invoke_threaded ).once
      @call.invoke
    end
    
    it "should return Thread" do
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      o = @call.invoke
      o.should be_instance_of( Thread )
      o.join
    end
  end
  
  describe Call, "inline DELETE" do
    
    before(:each) do
      @call = Call.delete( "http://test.com/resources/1" )
      @ok = Net::HTTPResponse::CODE_TO_OBJ['200'].new( "HTTP/1.0", 200, "OK" )
      @ok.stubs( :body ).returns( "" )
    end
    
    it "should initialize" do
      @call.should_not be_nil
    end
    
    it "should use Net::HTTP::Delete request" do
      @call.http_request.should be_an_instance_of( Net::HTTP::Delete )
    end
    
    it "should make DELETE request" do
      @call.expects( :invoke_threaded ).never
      Net::HTTP.any_instance.expects( :request ).with( @call.http_request, nil ).returns( @ok )
      @call.invoke
    end
  end
  
  describe Call, "raise on error" do
    
    before(:each) do
      @call = Call.get( "http://test.com/resources/1" )
    end
    
    it "should raise on error if requested" do
      error_response = stub( :code => 500, :message => "Server failed" )
      Net::HTTP.any_instance.expects( :request ).returns( error_response )
      @call.invoke
      lambda { @call.raise_on_error }.should raise_error( Net::HTTPError )
    end
  end
  
end
