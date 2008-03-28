# -*- ruby -*-

require 'rubygems'
require 'hoe'

$: << File.expand_path( File.join( File.dirname( __FILE__ ), 'lib' ) )
require 'suck'

Hoe.new('suck', Suck::VERSION) do |p|
  p.rubyforge_name = 'simplyruby'
  p.author = 'Matt Mower'
  p.email = 'self@mattmower.com'
  p.summary = 'A simple do-not-suck HTTP client for Ruby'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

# vim: syntax=Ruby
