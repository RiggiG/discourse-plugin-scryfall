# frozen_string_literal: true

# name: discourse-scryfall
# about: Converts [[card name]] to Scryfall search links for Onebox embeds
# meta_topic_id: TODO
# version: 0.0.2
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :scryfall_plugin_enabled

module ::ScryfallPlugin
  PLUGIN_NAME = "discourse-scryfall"
end

require_relative "lib/scryfall_plugin/engine"

after_initialize do
  # Process Scryfall syntax during markdown preprocessing
  on(:before_post_process_cooked) do |doc, post|
    if SiteSetting.scryfall_plugin_enabled
      ScryfallPlugin::CardHandler.process_links(doc)
    end
  end
end
