# frozen_string_literal: true

module ::ScryfallPlugin
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace ScryfallPlugin
  end
end
