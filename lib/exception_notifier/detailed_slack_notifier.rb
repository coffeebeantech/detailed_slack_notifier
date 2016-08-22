require 'slack-notifier'
require 'action_dispatch/http/request'

module ExceptionNotifier
  # notifier plugin for Slack, implementing both initialize and call
  class DetailedSlackNotifier
    def initialize(options = {})
      @webhook_url = options[:webhook_url]
      @notifier_options = options.select { |key, _value| %i(username channel).include?(key) }
    end

    def call(exception, options = {})
      notification = DetailedSlackNotification.new(exception, options)
      slack_notifier.ping notification.message, attachments: notification.attachments
    end

    private

    attr_reader :webhook_url, :username, :notifier_options

    def slack_notifier
      @slack_notifier ||= Slack::Notifier.new webhook_url, notifier_options
    end

    # this class builds Slack exception notifications
    class DetailedSlackNotification
      def initialize(exception, options = {})
        @exception = exception
        @env = options[:env]
        @data = ((env && env['exception_notifier.exception_data']) || {}).merge(options[:data] || {})
        @timestamp = Time.zone.now
      end

      def message
        msg = "#{exception.class.to_s =~ /^[aeiou]/i ? 'An' : 'A'} #{exception.class} occurred"
        msg << "#{background_exception? ? ' in background' : ''} at #{timestamp} :\n"
        msg << "#{exception.message}\n"
        msg
      end

      def attachments
        array = []

        unless background_exception?
          array << session_attachment
          array << request_attachment
        end

        array << backtrace_attachment
        array << data_attachment
      end

      private

      attr_reader :exception, :env, :data, :timestamp

      def request
        @request ||= ActionDispatch::Request.new(env)
      end

      def session_id
        id = '[FILTERED]'
        if request.ssl?
          id = request.session['session_id']
          id ||= (request.env['rack.session.options'] && request.env['rack.session.options'][:id]).inspect
        end
        id
      end

      def session_attachment
        {
          fallback: 'Session',
          title: 'Session',
          text: text_from_hash(
            'Session ID' => session_id,
            'Data' => JSON.pretty_generate(request.session.to_hash)
          ),
          color: '#444444'
        }
      end

      def request_attachment
        {
          fallback: 'Request',
          title: 'Request',
          text: text_from_hash(request_description),
          color: '#ff3399'
        }
      end

      def request_description
        {
          'URL' => request.url,
          'HTTP Method' => request.request_method,
          'IP address' => request.remote_ip,
          'Parameters' => request.filtered_parameters.inspect,
          'Timestamp' => timestamp.getutc,
          'Server' => Socket.gethostname,
          'Rails root' => Rails.root,
          'Process' => $PROCESS_ID
        }
      end

      def backtrace_attachment
        {
          fallback: 'Backtrace',
          title: 'Backtrace',
          text: (exception.backtrace || []).join("\n"),
          color: '#3399ff'
        }
      end

      def data_attachment
        {
          fallback: 'Data',
          title: 'Data',
          text: JSON.pretty_generate(data),
          color: '#33aa55'
        }
      end

      def text_from_hash(hash)
        hash.map { |k, v| "#{k}: #{v}" }.join("\n")
      end

      def background_exception?
        env.nil?
      end
    end
  end
end
