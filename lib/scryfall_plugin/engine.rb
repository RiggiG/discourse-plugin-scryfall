# frozen_string_literal: true

module ::ScryfallPlugin
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace ScryfallPlugin
    config.autoload_paths << File.join(config.root, "lib")
  end
end
