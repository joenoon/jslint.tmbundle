#!/usr/bin/env ruby
require ENV['TM_SUPPORT_PATH'] + '/lib/escape'

lib_dir = File.expand_path(File.dirname(__FILE__) + '/../vendor/jslint_on_rails/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'yaml'
require 'jslint/lint'
require 'jslint/utils'
default_config = File.join(lib_dir, 'jslint', 'config', 'jslint.yml')
custom_config = ENV['TM_JSLINT_CONFIG']
if custom_config && File.exist?(custom_config)
  JSLint.config_path = custom_config
else
  JSLint.config_path = default_config
end

module JSLint
  class Lint
    def run_to_output
      check_java
      arguments = "\"#{JSLINT_FILE}\" #{option_string} #{@file_list.map {|x| %Q{"#{x}"} }.join(' ')}"
      args = [ RHINO_JAR_FILE, RHINO_JAR_CLASS, arguments ]
      call_java_with_output(*args)
    end
    
    def call_java_with_output(jar, mainClass, arguments = "")
      cmd = %Q{java -cp "#{jar}" "#{mainClass}" #{arguments}}
      %x(#{cmd})
    end
    
  end
end

FILENAME = ENV['TM_FILENAME']
FILEPATH = ENV['TM_FILEPATH']
SUPPORT  = ENV['TM_BUNDLE_SUPPORT']

lint = JSLint::Lint.new :paths => [ FILENAME ]
output = lint.run_to_output

def lint!(output)

  output  = output.split(/\n/)
  # the result line will always be first
  results = output.shift
  # duplicate result like at bottom
  output.pop

  output  = output.join("\n")

  # Lint at line 2364 character 190
  output.gsub!(/Lint at line (\d+) character (\d+):/) do |match|
    %Q{<a href="txmt://open?url=file://#{e_url FILEPATH}&line=#{$1}&column=#{$2}">#{match}</a>}
  end

  output  = output.split(/\n\n/)
  output  = output.map do |chunk|
    chunk.strip!
    next if chunk.length == 0
    lines = chunk.split(/\n/)
    chunk = "<li>#{lines[0]}<pre><code>#{lines[1]}\n#{lines[2]}</code></pre></li>"
    chunk
  end
  output = output.reverse.join("\n\n")

  html = <<-HTML
<html>
  <head>
    <title>jslint results</title>
    <style type="text/css">
      body {
        font-size: 13px;
      }
      
      pre {
        background-color: #eee;
        color: #400;
        margin: 3px 0;
      }
      
      h1, h2 { margin: 0 0 5px; }
      
      h1 { font-size: 20px; }
      h2 { font-size: 16px;}
      
      span.warning {
        color: #c90;
        text-transform: uppercase;
        font-weight: bold;
      }
      
      span.error {
        color: #900;
        text-transform: uppercase;
        font-weight: bold;
      }
      
      ul {
        margin: 10px 0 0 20px;
        padding: 0;
      }
      
      li {
        margin: 0 0 10px;
      }
    </style>
  </head>
  <body>
    <h1>jslint</h1>
    <p>config: #{JSLint.config_path}</p>
    <h2>#{results}</h2>
    
    <ul>
      #{output}
    </ul>
  </body>
</html>  
HTML

  html
end

puts lint!(output)
