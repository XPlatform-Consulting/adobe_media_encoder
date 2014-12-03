require 'logger'
require 'optparse'
require 'pp'

require 'adobe_media_encoder/api/client'

module AdobeMediaEncoder

  module API

    class CLI

      LOGGING_LEVELS = {
        :debug => Logger::DEBUG,
        :info => Logger::INFO,
        :warn => Logger::WARN,
        :error => Logger::ERROR,
        :fatal => Logger::FATAL
      }

      attr_accessor :logger, :api

      def parse_arguments
        arguments = {
          :log_to => STDERR,
          :log_level => Logger::WARN,
          :options_file_path => File.expand_path(File.basename($0, '.*'), '~/.options'),
        }
        op = OptionParser.new
        op.on('--host-address HOSTADDRESS', 'The AdobeAnywhere server address.',
              "\tdefault: #{arguments[:host_address]}") { |v| arguments[:host] = v }
        op.on('--host-port PORT', 'The port on the AdobeAnywhere server to connect to.',
              "\tdefault: #{arguments[:port]}") { |v| arguments[:port] = v }
        op.on('--method-name METHODNAME', '') { |v| arguments[:method_name] = v }
        op.on('--method-arguments JSON', '') { |v| arguments[:method_arguments] = v }
        op.on('--pretty-print', '') { |v| arguments[:pretty_print] = v }
        op.on('--log-to FILENAME', 'Log file location.', "\tdefault: STDERR") { |v| arguments[:log_to] = v }
        op.on('--log-level LEVEL', LOGGING_LEVELS.keys, "Logging level. Available Options: #{LOGGING_LEVELS.keys.join(', ')}",
              "\tdefault: #{LOGGING_LEVELS.invert[arguments[:log_level]]}") { |v| arguments[:log_level] = LOGGING_LEVELS[v] }
        op.on('--[no-]options-file [FILENAME]', 'Path to a file which contains default command line arguments.', "\tdefault: #{arguments[:options_file_path]}" ) { |v| arguments[:options_file_path] = v}
        op.on_tail('-h', '--help', 'Show this message.') { puts op; exit }
        op.parse!(ARGV.dup)

        arguments_file_path = arguments[:options_file_path]
        # Make sure that arguments from the command line override those from the arguments file
        op.parse!(ARGV.dup) if op.load(arguments_file_path)
        arguments
      end


      def initialize(args = {})
        args = parse_arguments.merge(args)
        @logger = Logger.new(args[:log_to])
        logger.level = args[:log_level] if args[:log_level]
        args[:logger] = logger

        @api = AdobeMediaEncoder::API::Client.new(args)

        ## LIST METHODS
        #methods = api.methods; methods -= Object.methods; methods.sort.each { |method| puts "#{method} #{api.method(method).parameters rescue ''}" }; exit

        # http.log_request_body = true
        # http.log_response_body = true
        # http.log_pretty_print_body = true


        method_name = args[:method_name]
        send(method_name, args[:method_arguments], :pretty_print => args[:pretty_print]) if method_name

      end

      def send(method_name, method_arguments, args = {})
        method_name = method_name.to_sym
        logger.debug { "Executing Method: #{method_name}" }

        send_arguments = [ method_name ]

        if method_arguments
          method_arguments = JSON.parse(method_arguments) if method_arguments.is_a?(String) and method_arguments.start_with?('{', '[')
          send_arguments << method_arguments
        end

        response = api.__send__(*send_arguments)
        puts response.respond_to?(:body) ? response.body : response

        exit
      end

      # CLI
    end
    # API
  end
  # AdobeMediaEncoder
end
