require "logstash/namespace"
require "logstash/outputs/base"
require "java"

# File output.
#
# Write events as one line JSON records to disk
#
class LogStash::Outputs::MetlogFile < LogStash::Outputs::Base

  config_name "metlog_file"

  # Only handle events with all of these tags
  # Optional.
  config :tags, :validate => :array, :default => []

  # The path to the file to write. Event fields can be used here,
  # like "/var/log/logstash/%{@source_host}/%{application}"
  config :path, :validate => :string, :required => true

  public
  def register
      puts "[#{self}] We have a logger in metlog_file output: [#{@logger}]"
      require "fileutils" # For mkdir_p
      @fileclient = FileClient.new(@path, @logger)
      @push_thread = Thread.new(@fileclient) do |client|
          client.run
      end
  end # def register

    public
    def receive(event)
        if !@tags.empty?
            if (event.tags & @tags).size != @tags.size
                return
            end
        end
        @fileclient.enqueue(event)
    end # def receive


    ############
    ############
    ############
    ############
    #
    #
    #
    # We need a separate thread to append to a log file or else we
    # will block as events come in.
    # Only flush the bufffers when we have idle time
    class FileClient
        include com.mozilla.services.ISignalFunction

        public
        def initialize(path, logger)
            @path = path
            @queue  = Queue.new
            @logger = logger

            @logfile = open(path)

            # Hook SIGHUP (1) to this client
            @signal = com.mozilla.services.Signal.getInstance()
            @signal.register_callback(1, this)
        end 

        public
        def invoke(signal)
            # TODO: do something here to respond to a signal
            puts  "Got signal: #{signal}"
        end

        public
        def run
            loop do
                begin
                    # batch up messages from the queue and
                    # reconstitute a 'large' JSON message to POST up
                    msgs = []
                    while @queue.length > 0
                        # append to disk as they come in
                        event = @queue.pop
                        @logfile.puts(event.to_json)
                    end
                    @logfile.flush
                    sleep 1
                rescue => e
                    @logger.warn(["http output exception", @socket, $!])
                    @logger.debug(["backtrace", e.backtrace])
                    break
                end
            end
        end # def run

        private
        def open(path)
            if File.directory?(path)
                raise ArgumentError, "Plugin expects a path to a file, not a directory."
            end

            @logger.info("Opening file", :path => path)

            dir = File.dirname(path)
            if !Dir.exists?(dir)
                @logger.info("Creating directory", :directory => dir)
                FileUtils.mkdir_p(dir)
            end

            return File.new(path, "a")
        end

        public
        def enqueue(msg)
            @queue.push(msg)
        end # def enqueue 

    end # class Client

end # class LogStash::Outputs::MetlogFile



