suck
  v1.0.1
  by Matt Mower <self@mattmower.com>
  http://matt.blogs.it/

== DESCRIPTION:

A simple HTTP client for Ruby that is meant to not suck. It does of course, but it works for me. YMMV.

== FEATURES/PROBLEMS:
  
* Implements HTTP calls, probably the wrong abstraction <sigh>

== SYNOPSIS:

A real-life example use of Suck:

<code>
call = Suck::Call.post( PLAYBACK_API_URL, :threaded => false )
call.invoke( :unique_id => params[:media_id], :profile => xml )

if call.ok?
  LOGGER.debug( "#{Time.now.to_s}: Caching embedding." )
  CACHE[content_key] = call.response.body
else
  LOGGER.warning( "#{Time.now.to_s}: Failed to get embedding: #{call.status_code} #{call.status_message}!" )
end
</code>

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

sudo gem install suck

== ACKNOWLEDGEMENTS

Suck uses the reverse_merge and reverse_merge! methods from the ActiveSupport library. To avoid a dependency on that library those methods are duplicated in Suck.

== LICENSE:

(The MIT License)

Copyright (c) 2008 Matt Mower <self@mattmower.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
