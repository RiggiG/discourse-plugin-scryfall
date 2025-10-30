# frozen_string_literal: true

# name: discourse-plugin-scryfall
# about: Converts [[card name]] to Scryfall search links for Onebox embeds
# meta_topic_id: TODO
# version: 0.2.0
# authors: RiggiG
# url: TODO
# required_version: 2.7.0

enabled_site_setting :scryfall_plugin_enabled

module ::ScryfallPlugin
  PLUGIN_NAME = "discourse-plugin-scryfall"
end

require_relative "lib/scryfall_plugin/engine"

after_initialize do
  # Register client-side assets
  register_asset "stylesheets/scryfall.scss"

  # Process raw markdown before post creation
  on(:before_create_post) do |post|
    if SiteSetting.scryfall_plugin_enabled && post.raw
      post.raw = ScryfallPlugin::CardHandler.process_raw_content(post.raw)
    end
  end

  # Customize Scryfall inline oneboxes
  on(:reduce_cooked) do |fragment, post|
    ScryfallPlugin::InlineCustomizer.customize_inline_oneboxes(fragment)
  end

  # Extend PostRevisor to handle edits
  PostRevisor.prepend(ScryfallPlugin::PostRevisorExtension)
end
