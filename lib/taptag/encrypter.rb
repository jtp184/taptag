module Taptag
  class Encrypter
    attr_accessor :algorithm

    def initialize(algo)
      @algorithm = if algo.is_a?(Symbol)
                     method(algo)
                   elsif algo.respond_to?(:call)
                     algo
                   else
                     raise ArgumentError, "Can't pass string to #{algo.class}"
                   end
    end

    def call(str)
      algorithm.call(str)
    end
  end
end
