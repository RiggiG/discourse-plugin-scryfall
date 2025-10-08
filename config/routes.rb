# frozen_string_literal: true

ScryfallPlugin::Engine.routes.draw do
  # No routes needed for this plugin - it only processes markdown
end

#Discourse::Application.routes.draw { mount ::ScryfallPlugin::Engine, at: "scryfall" }
