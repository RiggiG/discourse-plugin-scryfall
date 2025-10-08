# frozen_string_literal: true

module ::ScryfallPlugin
  class Engine < ::Rails::Engine
    engine_name "scryfall_plugin"
    isolate_namespace ScryfallPlugin
  end
end
