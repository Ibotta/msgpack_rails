begin
  # load msgpack gem first so we can overwrite its to_msgpack.
  require "msgpack"
rescue LoadError
end

# The msgpack gem adds a few modules to Ruby core classes containing :to_msgpack definition, overwriting
# their default behavior using as_msgpack. We need to define the basic to_msgpack method in all of them,
# otherwise they will always use to_msgpack gem implementation.
[Object, NilClass, TrueClass, FalseClass, Fixnum, Bignum, Float, String, Array, Hash, Symbol].each do |klass|
  klass.class_eval do
    alias_method :msgpack_to_msgpack, :to_msgpack if respond_to?(:to_msgpack)

    # Dumps object to msgpack format string
    # @param [Hash] options
    # @return [String] msgpack data
    def to_msgpack(options = nil)
      ActiveSupport::MessagePack.encode(self, options)
    end

  end
end
