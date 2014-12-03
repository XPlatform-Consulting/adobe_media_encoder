require 'logger'
require 'net/http'
require 'net/https'

require 'adobe_media_encoder'

class String

  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').collect(&:capitalize).join
  end
  alias :camelize :camel_case

  def camel_case_lower
    camel_case.uncapitalize
  end

  def snake_case
    self.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr('-', '_').downcase
  end
  alias snakeize :snake_case

  def uncapitalize
    self[0, 1].downcase + self[1..-1]
  end

end

module AdobeMediaEncoder

  module API

    class Client

      class XMLHelper

        def self.create_manifest(data)
          <<-XML
<?xml version='1.0'?>
<manifest version='1.0'>#{ data.map { |k,v| _k = k.to_s.camel_case; "\n\t<#{_k}>#{v.to_s}</#{_k}>"}.join }
</manifest>
          XML
        end

        def self.parse_payload(xml)
          doc = REXML::Document.new(xml)
          Hash[doc.elements['/payload'].elements.map { |e| [ e.name, e.text ] } ]
        end

      end

      class HTTPClient

        DEFAULT_HTTP_HOST_NAME = 'localhost'
        DEFAULT_HTTP_HOST_PORT = 8080

        attr_accessor :logger, :log_request_body, :log_response_body, :log_pretty_print_body,

                      :host, :port, :http, :request, :response, :default_request_headers,

                      :base_uri

        def initialize(args = { })
          initialize_logger(args)
          initialize_http(args)

          @default_request_headers = {
              'Content-Type' => 'application/xml; charset=utf-8',
              'Accept' => 'application/xml',
          }
          @parse_response = true

          @base_uri = "http://#{host}:#{port}/"

          @log_request_body = args.fetch(:log_request_body, true)
          @log_response_body = args.fetch(:log_response_body, true)
          @log_pretty_print_body = args.fetch(:log_pretty_print_body, true)
        end

        def initialize_logger(args = { })
          @logger = args[:logger] ||= Logger.new(args[:log_to] || STDERR)
          log_level = args[:log_level]
          if log_level
            @logger.level = log_level
            args[:logger] = @logger
          end
          @logger
        end

        def initialize_http(args = { })
          @host = args[:host] ||= DEFAULT_HTTP_HOST_NAME
          @port = args[:port] ||= DEFAULT_HTTP_HOST_PORT
          @http = Net::HTTP.new(host, port)
        end

        # Formats a HTTPRequest or HTTPResponse body for log output.
        # @param [HTTPRequest|HTTPResponse] obj
        # @return [String]
        def format_body_for_log_output(obj)
          #obj.body.inspect
          output = ''
          if obj.content_type == 'application/json'
            if @log_pretty_print_body
              _body = obj.body
              output << "\n"
              output << JSON.pretty_generate(JSON.parse(_body)) rescue _body
              return output
            else
              return obj.body
            end
          else
            return obj.body.inspect
          end
        end

        def send_request(request)
          @request = request
          logger.debug { %(REQUEST: #{request.method} http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}#{request.path} HEADERS: #{request.to_hash.inspect} #{log_request_body and request.request_body_permitted? ? "BODY: #{format_body_for_log_output(request)}" : ''}) }

          @response = http.request(request)
          logger.debug { %(RESPONSE: #{response.inspect} HEADERS: #{response.to_hash.inspect} #{log_response_body and response.respond_to?(:body) ? "BODY: #{format_body_for_log_output(response)}" : ''}) }

          @parse_response ? response_parsed : response.body
        end

        def response_parsed
          XMLHelper.parse_payload(response.body) rescue response
        end

        def build_uri(path = '', query = { })
          _query = query.is_a?(Hash) ? query.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join('&') : query
          _path = "#{path}#{_query and _query.respond_to?(:empty?) and !_query.empty? ? "?#{_query}" : ''}"
          URI.parse(File.join(base_uri, _path))
        end

        def delete(path, options = { })
          query = options.fetch(:query, { })
          @uri = build_uri(path, query)
          request = Net::HTTP::Delete.new(@uri.request_uri, default_request_headers)
          send_request(request)
        end

        def get(path, query = nil, options = { })
          query ||= options.fetch(:query, { })
          @uri = build_uri(path, query)
          request = Net::HTTP::Get.new(@uri.request_uri, default_request_headers)
          send_request(request)
        end

        def put(path, body, options = { })
          query = options.fetch(:query, { })
          @uri = build_uri(path, query)
          #body = JSON.generate(body) unless body.is_a?(String)

          request = Net::HTTP::Put.new(@uri.request_uri, default_request_headers)
          request.body = body
          send_request(request)
        end

        def post(path, body = nil, options = { })
          query = options.fetch(:query, { })
          @uri = build_uri(path, query)
          #body = JSON.generate(body) unless body.is_a?(String)

          request = Net::HTTP::Post.new(@uri.request_uri, default_request_headers)
          request.body = body
          send_request(request)
        end

      end

      attr_accessor :http

      def initialize(args = { })
        initialize_logger(args)
        @http = HTTPClient.new(args)
      end

      def initialize_logger(args = { })
        @logger = args[:logger] ||= Logger.new(args[:log_to] || STDOUT)
        log_level = args[:log_level]
        if log_level
          @logger.level = log_level
          args[:logger] = @logger
        end
        @logger
      end

      def normalize_args(args = { }, options = { })
        case args
          when Array
            [*args].map { |a| normalize_args(a, options) } if normalize_args.is_a?(Array)
          when Hash
            symbolize_keys = options.fetch(:symbolize_keys, true)
            camelize_keys = options.fetch(:camelize_keys, false)
            uncapitalize_keys = options.fetch(:uncapitalize_keys, false)
            downcase_keys = options.fetch(:downcase_keys, false)
            Hash[args.map do |k, v|
                   _k = k.dup rescue k
                   _k = _k.to_s.camel_case if camelize_keys rescue _k
                   _k = _k.to_s.uncapitalize if uncapitalize_keys rescue _k
                   _k = _k.to_s.downcase if downcase_keys rescue _k
                   _k = symbolize_keys ? _k.to_sym : _k.to_s rescue _k
                   [_k, v ]
                 end]
          else
            args
        end
      end

      def job_abort(args = { })
        args = normalize_args(args, :symbolize_keys => true, :downcase_keys => true)
        job_id = args[:id] || args[:job_id] || args[:jobid]
        http.delete("job#{job_id ? "?jobID=#{job_id}" : ''}")
      end

      def job_history(args = { })
        http.get('history')
      end

      def job_status(args = { })
        http.get('job')
      end

      def job_submit(args = { })
        args = normalize_args(args, :symbolize_keys => false, :camelize_keys => true)
        xml = XMLHelper.create_manifest(args)
        http.post('job', xml)
      end

      def server_kill(args = { })
        http.delete('server')
      end

      def server_restart(args = { })
        http.post('server')
      end

      def server_status(args = { })
        http.get('server')
      end

    end

  end

end
