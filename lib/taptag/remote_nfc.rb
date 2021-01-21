require 'drb/drb'
require 'forwardable'

module Taptag
  # Access an NFC reader being served over DRb
  class RemoteNFC
    extend Forwardable

    def_delegators :drb_object, :method_missing, :respond_to?

    def initialize(args = {})
      args.map do |k, v|
        instance_variable_set(:"@#{k}", v)
      end
    end

    private

    def server_uri
      "druby://#{@url || @ip_address}:#{@port}"
    end

    def drb_object
      return @drb_object if @drb_object

      DRb.start_service
      @drb_object = DRbObject.new_with_uri(server_uri)
    end
  end
end
