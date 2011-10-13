require_relative "helper"
require "rack/mime"

# ATTENTION! ACTHUNG!
#
# You'll need some static data located in the same directory were this
# file is located, or set the proper path by changing STATIC_ROOT.
#
# If you like to, you can download some basic HTML and images in the
# following URL:
#
# http://dl.dropbox.com/u/2247903/andale-static.tar.gz
#

STATIC_ROOT = File.expand_path("../static/", __FILE__)

class StaticServer < Andale
  def serve request, response
    puts "#{Time.now} #{request.method} #{request.url}"

    # Basic routing
    file = if request.url == "/"
             "index.html"
           else
             request.url[1..-1]
           end

    # Change directory context for sending files
    Dir.chdir STATIC_ROOT do
      headers, data = file_contents file
      response.send headers, data
    end

    response.fin!
  end

  def file_contents file
    headers = { "status" => "200 OK" }
    headers["Content-Type"] = Rack::Mime.mime_type File.extname(file)

    # File contents
    data = if File.exists? file
             File.binread(file)
           else
             headers["Content-Type"] = "text/plain"
             headers["status"]       = "404 Not Found"

             "404 Not Found"
           end

    headers["Content-Length"] = data.size.to_s

    [ headers, data ]
  end
end

run StaticServer
