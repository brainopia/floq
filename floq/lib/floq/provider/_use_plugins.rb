class Floq::Provider
  def self.use(*args)
    default.use *args
  end

  def use(*args)
    clone.use! *args
  end

  def use!(type, *args)
    plugin = Detector.plugin type, args
    wrap type, plugin, *args
    reset_chain
    self
  end

  module Detector
    Plugins = Floq::Plugins

    def self.plugin(type, args)
      camelized_type = camelize type

      if Plugins.const_defined? camelized_type
        Plugins.const_get camelized_type
      else
        camelized_type += 's'
        if Plugins.const_defined? camelized_type
          namespace = Plugins.const_get camelized_type
          plugin_name = camelize args.shift
          namespace.const_get plugin_name
        else
          raise ArgumentError, "can not find #{type} plugin"
        end
      end
    end

    def self.camelize(string)
      string.to_s.split('_').map(&:capitalize).join
    end
  end
end
