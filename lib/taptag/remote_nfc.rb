require 'drb/drb'

module Taptag
  # Access an NFC reader being served over DRb
  class RemoteNFC
    class << self
      # Reader for the uri, with some defaults
      def server_uri
        return @server_uri if @server_uri
        return @server_uri = ENV['DRB_URL'] if ENV['DRB_URL']

        server_url = File.exist?('.raspi-hostname') ? File.read('.raspi-hostname') : '127.0.0.1'
        @server_uri = "druby://#{server_url}:#{port}"
      end

      # Set the uri to the +new_uri+, an nils the drb object
      def server_uri=(new_uri)
        @drb_object = nil
        @server_uri = new_uri
      end

      # Reader for the port to construct a uri with, defaults to 8787
      def port
        @port ||= 8787
      end

      # Set the port to +new_port+ and nils the drb object
      def port=(new_port)
        @drb_object = nil
        @port = new_port
      end

      # Defer to drb_object to see if we can respond to +mtd+
      def respond_to_missing?(mtd)
        drb_object.respond_to?(mtd) ? true : super
      end

      # Redirect missing method by +method_name+, passing +args+ and +blk+ to the drb_object
      def method_missing(method_name, *args, &blk)
        super unless drb_object.respond_to?(method_name)

        drb_object.public_send(method_name, *args, &blk)
      end

      private

      # Instantiates and memoizes the DRb object to use for NFC functions
      def drb_object
        return @drb_object if @drb_object

        start_service
        @drb_object = DRbObject.new_with_uri(server_uri)
      end

      # Starts the DRb service, memoizing so that it's done the once on the client
      def start_service
        return if @started

        DRb.start_service
        @started = true
      end
    end
  end
end
