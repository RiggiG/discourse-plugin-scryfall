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
  # Process raw markdown before post creation
  #on(:before_create_post) do |post|
  #  if SiteSetting.scryfall_plugin_enabled && post.raw
  #    Rails.logger.info "Scryfall: Processing raw content before creation"
  #    post.raw = ScryfallPlugin::CardHandler.process_raw_content(post.raw)
  #  end
  #end

  # Process raw markdown during cooking (handles edits)
  on(:before_post_process_cooked) do |doc, post|
    if SiteSetting.scryfall_plugin_enabled && post.raw
      Rails.logger.info "Scryfall: Processing raw content during cooking"
      original_raw = post.raw
      processed_raw = ScryfallPlugin::CardHandler.process_raw_content(post.raw)
      if processed_raw != original_raw
        post.raw = processed_raw
      end
    end
  end
end
