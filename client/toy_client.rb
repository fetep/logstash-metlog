# This is a toy client sending messages to the logging infrastructure
#
require "socket"
require 'ffi-rzmq'
require "json"
require 'time'

DEBUG = true








######## Start internal logging to stdout #########
def INFO(msg)
    if DEBUG
        puts "INFO: " + msg
    end
end

def WARNING(msg)
    if DEBUG
        puts 'WARNING: ' + msg
    end
end

def ERROR(msg)
    if DEBUG
        puts 'ERROR: ' + msg
    end
end


######## End internal logging to stdout #########












# TODO:
# Can we add required and default arguments here?
# Rubydoc strings?  Optional stacktraces and the like would be nice
def log(transport, data_hash) 
    transport.send(JSON(data_hash).to_s)
end

class Transport
    # This is the parent calss of transports
    def encode(json_obj)
        # This doesn't actually send to anything 
        INFO "Serializing to string"
        return json_obj.to_s
    end

    def destroy
        # Nothing to see here!
    end
end

class ZeroMQTransport < Transport
    def initialize(bind_string, queue_length=1000)
        @context = ZMQ::Context.new
        # We send updates via this socket
        @publisher = @context.socket(ZMQ::PUB)
        @publisher.setsockopt(ZMQ::HWM, queue_length)
        @publisher.connect(bind_string)
    end

    def send(json_obj)
        message = encode(json_obj)
        @publisher.send_string(message)
    end

    def destroy
        @publisher.close
    end
end

class UDPTransport < Transport
    def initialize(host, port)
        @host = host
        @port = port
    end

    def send(json_obj)
        # huh - you don't need to specify the method name.  super just
        # calls it for you.
        msg = encode(json_obj)

        if msg.length > 512
            WARNING "Messages > 512 bytes may be lost!"
        end

        INFO "Sending UDP data to #{@host}:#{@port}"
        s = UDPSocket.new

        # This sucks - send throws :
        #   SocketERROR: send: name or service not known
        #       send at org/jruby/ext/socket/RubyUDPSocket.java:300
        # if the message is too large??  maybe this is UDP falling
        # back TCP for multipacket messages?
        flags = 0
        begin
            s.send(msg, flags, @host, @port)
            INFO "Message sent!"
        rescue SocketError => detail
            ERROR "Something went wrong. Details: [#{detail}]"
            WARNING "Message NOT sent!"
        ensure
            s.close()
        end
    end

end


def udp_main
    transport = UDPTransport.new('localhost', 2294)
    log(transport, {'message' => 'This is some text'})

    # Send a crazy large message
    log(transport, {'message' => 'blah blah' * 200000})
    INFO "Done!"
end


SEVERITY = {
    EMERGENCY: 0,
    ALERT: 1,
    CRITICAL: 2,
    ERROR: 3,
    WARNING: 4,
    NOTICE: 5,
    INFORMATIONAL: 6,
    DEBUG: 7,
}


def zeromq_main
    # Now broadcast exactly 10 updates with pause
    transport = ZeroMQTransport.new("tcp://127.0.0.1:5565", 1000)

    # Note that the ZMQ client will asynchronously bind into the
    # subscriber so the first couple messages may be lost until the
    # sync code it put in
    msg1 = { timestamp: '2011-10-13T09:43:44.386392',
            metadata: {'some_data' => 'foo' },
            logger: 'toy1',
            severity: SEVERITY[:EMERGENCY],
            message: 'some log text',
    }

    msg2 = { timestamp: '2011-10-13T09:43:44.386392',
            metadata: {'some_data' => 'bar' },
            logger: 'toy2',
            severity: SEVERITY[:EMERGENCY],
            message: 'some log text',
    }

    sleep 2
    100.times do |x|
        #msg1['timestamp'] = Time.now.iso8601
        #msg1['counter'] = x
        log(transport, msg1)
    end

    transport.destroy
end

zeromq_main()

