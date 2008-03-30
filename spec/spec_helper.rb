$: << File.join( File.dirname( __FILE__ ), '..', 'lib' )

require 'mocha'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def form_encode(form,sep='&')
  form.map {|k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }.join(sep)
end

# Copied from net/http.rb to allow testing of POST'd content
def urlencode(str)
  str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
end
