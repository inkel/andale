# Ándale: a simple SPDY framework

Ándale is a simply SPDY framework that provides a very simple server
that uses
[Ilya Grigorik's `spdy` gem](https://github.com/igrigorik/spdy) to
respond to SPDY requests.

Ándale is built using
[EventMachine](https://github.com/eventmachine/eventmachine), though
at this stage it's not making full usage of EventMachine's capabilities.

It's usage is, at this stage, very simple: you just need to inherit
from `Andale` and override the `serve(request, response)` method:

```ruby
class Hello < Andale
  def serve request, response
    response.send({ "status" => "200 OK", "Content-Type" => "text/plain" }, data)
    response.fin!
  end
end

EM.run do
  EM.start_server "0.0.0.0", 10000, klass
end
```

## TODO

There are plenty of things to do in Ándale. If you find any issue or
would like to contribute, please visit the
[issues page](https://github.com/inkel/andale/issues).
