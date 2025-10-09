# frozen_string_literal: true

# name: discourse-scryfall
# about: Converts [[card name]] to Scryfall search links for Onebox embeds
# meta_topic_id: TODO
# version: 0.0.4
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :scryfall_plugin_enabled

module ::ScryfallPlugin
  PLUGIN_NAME = "discourse-scryfall"
end

require_relative "lib/scryfall_plugin/engine"

after_initialize do
  # Custom onebox engine is automatically loaded from lib/onebox/
  # No registration needed

  # Process raw markdown before post creation
  on(:before_create_post) do |post_creator|
    if SiteSetting.scryfall_plugin_enabled
      Rails.logger.info "Scryfall: Processing raw content before post creation"
      post_creator.opts[:raw] = ScryfallPlugin::CardHandler.process_raw_content(post_creator.opts[:raw])
    end
  end
end
