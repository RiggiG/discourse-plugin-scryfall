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
  # Process raw markdown before post creation
  on(:before_create_post) do |post|
    if SiteSetting.scryfall_plugin_enabled && post.raw
      post.raw = ScryfallPlugin::CardHandler.process_raw_content(post.raw)
    end
  end

  # Customize inline oneboxes AFTER all post processing is complete
  # This runs after CookedPostProcessor.process_inline_onebox has set the title
  on(:post_process_cooked) do |doc, post|
    next unless SiteSetting.scryfall_plugin_enabled
    
    ScryfallPlugin::InlineCustomizer.customize_inline_oneboxes_in_doc(doc, post)
  end

  # Extend PostRevisor to handle edits
  PostRevisor.prepend(ScryfallPlugin::PostRevisorExtension)
end
