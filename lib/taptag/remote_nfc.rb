require 'drb/drb'

module Taptag
  # Access an NFC reader being served over DRb
  class RemoteNFC
    class << self
      def server_uri
        return @server_uri if @server_uri
        return @server_uri = ENV['DRB_URL'] if ENV['DRB_URL']

        server_url = File.exist?('.raspi-hostname') ? File.read('.raspi-hostname') : '127.0.0.1'
        @server_uri = "druby://#{server_url}:#{port}"
      end

      def server_uri=(new_uri)
        @drb_object = nil
        @server_uri = new_uri
      end

      def port
        @port ||= 8787
      end

      def port=(new_port)
        @drb_object = nil
        @port = new_port
      end

      def respond_to_missing?(mtd)
        drb_object.respond_to?(mtd) ? true : super
      end

      def method_missing(method_name, *args, &blk)
        super unless drb_object.respond_to?(method_name)

        drb_object.public_send(method_name, args, &blk)
      end

      private

      def drb_object
        return @drb_object if @drb_object

        start_service
        @drb_object = DRbObject.new_with_uri(server_uri)
      end

      def start_service
        return if @started

        DRb.start_service
      end
    end
  end
end
