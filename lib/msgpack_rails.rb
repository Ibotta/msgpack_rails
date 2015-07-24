require "active_support"
require "msgpack_rails/version"

#load activesupport plugin for encoder
module ActiveSupport

  eager_autoload do
    autoload :MessagePack, "msgpack_rails/activesupport/message_pack"
  end

end

#load activemodel serializer plugin
if defined?(ActiveModel)
  module ActiveModel
    module Serializers

      eager_autoload do
        autoload :MessagePack, "msgpack_rails/activemodel/serializers/message_pack"
      end

    end
  end
end

#load rails activerecord and responders
if defined?(::Rails)
  module MsgpackRails
    class Rails < ::Rails::Engine
      initializer "msgpack_rails" do

        if defined?(::ActiveRecord::Base)
          ::ActiveSupport.on_load(:active_record) do
            ::ActiveRecord::Base.send(:include, ActiveModel::Serializers::MessagePack)
          end
        end

        if defined?(::Mongoid::Document)
          ::ActiveSupport.on_load(:mongoid) do
            ::Mongoid::Document.send(:include, ActiveModel::Serializers::MessagePack)
          end
        end

        #to_json and to_yml are also undef-ed in responders
        if defined?(::Responders)
          ::ActionController::Responder.send :undef_method, :to_msgpack
        end

        ::Mime::Type.register "application/x-msgpack", :msgpack
        ::ActionController::Renderers.add :msgpack do |item, options|
          self.content_type ||= Mime::MSGPACK
          item.respond_to?(:to_msgpack) ? item.to_msgpack : item
        end

      end
    end
  end
end
