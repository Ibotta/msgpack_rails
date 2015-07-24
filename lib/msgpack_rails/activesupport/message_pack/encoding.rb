require "active_support/json"
require "msgpack_rails/activesupport/core_ext/object/to_msgpack"

module ActiveSupport

  class << self
    delegate :msgpack_stringify_hash_keys, :msgpack_stringify_hash_keys=,
      :to => :'ActiveSupport::MessagePack::Encoding'
  end

  #encoder module which helps with detecting circular references
  # mostly lifted from ActiveSupport::JSON
  module MessagePack

    #encodes a value to msgpack string. uses Encoder class
    # @param [Object] value to encode
    # @param [Hash] options
    # @return [String] encoded
    def self.encode(value, options = nil)
      Encoding::Encoder.new(options).encode(value)
    end

    module Encoding
      class CircularReferenceError < StandardError; end

      class Encoder
        attr_reader :options

        # init
        # @param [Hash] options
        def initialize(options = nil)
          @options = options || {}
          @seen = Set.new
        end

        #encodes a value to msgpack string. leaves out circular references
        # @param [Object] value to encode
        # @param [Boolean] use_options to use encoder options when calling as_msgpack
        # @return [String] encoded
        def encode(value, use_options = true)
          check_for_circular_references(value) do
            packed = use_options ? value.as_msgpack(options_for(value)) : value.as_msgpack
            packed.msgpack_to_msgpack(options)
          end
        end

        # like encode, but only calls as_msgpack, without encoding to string
        # @param [Object] value to encode
        # @param [Boolean] use_options to use encoder options when calling as_msgpack
        # @return [Object] value transformed ready for encoding
        def as_msgpack(value, use_options = true)
          check_for_circular_references(value) do
            use_options ? value.as_msgpack(options_for(value)) : value.as_msgpack
          end
        end

        def options_for(value)
          if value.is_a?(Array) || value.is_a?(Hash)
            # hashes and arrays need to get encoder in the options, so that they can detect circular references
            options.merge(:encoder => self)
          else
            options.dup
          end
        end

        private

        def check_for_circular_references(value)
          unless @seen.add?(value.__id__)
            raise CircularReferenceError, 'object references itself'
          end
          yield
        ensure
          @seen.delete(value.__id__)
        end
      end

      class << self
        attr_accessor :msgpack_stringify_hash_keys
      end

      #turn hash keys to strings like json (default true)
      self.msgpack_stringify_hash_keys = true
    end

  end

end

class Object
  # get object representation for msgpack encoding. delegates to as_json from ActiveSupport
  # @param [Hash] options
  # @return [Object]
  def as_msgpack(options = nil)
    #delegate majority of as_msgpack to rails as_json
    as_json(options)
  end
end

module Enumerable
  # get enumerable representation for msgpack encoding, delegates each item to as_msgpack
  # @param [Hash] options
  # @return [Array] always returns an array
  def as_msgpack(options = nil) #:nodoc:
    to_a.as_msgpack(options)
  end
end

class Array
  # get array representation for msgpack encoding, delegates each item to as_msgpack. Avoids circular references
  # @param [Hash] options
  # @return [Array]
  def as_msgpack(options = nil) #:nodoc:
    # use encoder as a proxy to call as_json on all elements, to protect from circular references
    encoder = options && options[:encoder] || ActiveSupport::MessagePack::Encoding::Encoder.new(options)
    map { |v| encoder.as_msgpack(v, options) }
  end
end

class Hash
  # get hash representation for msgpack encoding, delegates each item to as_msgpack. Avoids circular references and adds only/except (like as_json)
  # @param [Hash] options
  # @return [Hash]
  def as_msgpack(options = nil) #:nodoc:
    # create a subset of the hash by applying :only or :except
    subset = if options
      if attrs = options[:only]
        slice(*Array.wrap(attrs))
      elsif attrs = options[:except]
        except(*Array.wrap(attrs))
      else
        self
      end
    else
      self
    end

    # use encoder as a proxy to call as_json on all values in the subset, to protect from circular references
    encoder = options && options[:encoder] || ActiveSupport::MessagePack::Encoding::Encoder.new(options)
    result = self.is_a?(ActiveSupport::OrderedHash) ? ActiveSupport::OrderedHash : Hash
    result[subset.map { |k, v| k = ActiveSupport::MessagePack::Encoding.msgpack_stringify_hash_keys ? k.to_s : k; [k, encoder.as_msgpack(v, options)] }]
  end
end
