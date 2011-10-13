require_relative "../lib/andale"

def run klass
  EM.run do
    Signal.trap("INT")  { EventMachine.stop }
    Signal.trap("TERM") { EventMachine.stop }

    EM.start_server "0.0.0.0", 10000, klass
  end
end
