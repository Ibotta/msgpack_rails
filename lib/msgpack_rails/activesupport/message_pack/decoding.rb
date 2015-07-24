module ActiveSupport
  mattr_accessor :parse_msgpack_times

  module MessagePack

    # decode string as msgpack
    # will parse time strings as datetime if parse_msgpack_times set
    # @param [String] data msgpack string
    # @return [Object] msgpack decoded data
    def self.decode(data)
      data = ::MessagePack.unpack(data)
      if ActiveSupport.parse_msgpack_times
        ActiveSupport::JSON.send(:convert_dates_from, data)
      else
        data
      end
    end

  end
end
