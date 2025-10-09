# frozen_string_literal: true

# name: discourse-plugin-scryfall
# about: Converts [[card name]] to Scryfall search links for Onebox embeds
# meta_topic_id: TODO
# version: 0.1.0
# authors: RiggiG
# url: TODO
# required_version: 2.7.0

enabled_site_setting :scryfall_plugin_enabled

module ::ScryfallPlugin
  PLUGIN_NAME = "discourse-plugin-scryfall"
end

require_relative "lib/scryfall_plugin/engine"

after_initialize do
  # Helper lambda to process scryfall content
  process_scryfall_content = lambda do |post|
    if SiteSetting.scryfall_plugin_enabled && post.raw
      Rails.logger.info "Scryfall: Processing raw content"
      post.raw = ScryfallPlugin::CardHandler.process_raw_content(post.raw)
    end
  end

  # Process raw markdown before post creation
  on(:before_create_post) do |post|
    process_scryfall_content.call(post)
  end

  # Process raw markdown before post update
  on(:before_update_post) do |post|
    process_scryfall_content.call(post)
  end
end
