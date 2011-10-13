require_relative "helper"

class HelloWorld < Andale
  def serve request, response
    puts "#{Time.now} #{request.method} #{request.url}"

    data = "Hello, World!\n"

    request.headers.sort.each do |header, value|
      data << "\n#{header}: #{value}"
    end

    response.send({ "status" => "200 OK", "Content-Type" => "text/plain" }, data)
    response.fin!
  end
end

run HelloWorld
