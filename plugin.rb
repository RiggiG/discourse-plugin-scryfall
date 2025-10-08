# frozen_string_literal: true

# name: discourse-plugin-scryfall
# about: Converts [[card name]] to Scryfall search links for Onebox embeds
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :scryfall_plugin_enabled

module ::ScryfallPlugin
  PLUGIN_NAME = "discourse-plugin-scryfall"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  # Register markdown processor for Scryfall card links
  on(:before_post_process_cooked) do |doc, post|
    if SiteSetting.scryfall_plugin_enabled
      ScryfallPlugin.process_scryfall_links(doc)
    end
  end
end

module ::ScryfallPlugin
  def self.process_scryfall_links(doc)
    doc.css('p').each do |paragraph|
      next if paragraph.content.exclude?('[[')
      
      new_html = paragraph.inner_html.gsub(/\[\[([^\]]+)\]\]/) do |match|
        card_name = $1.strip
        encoded_name = CGI.escape(card_name)
        scryfall_url = "https://scryfall.com/search?q=#{encoded_name}&unique=cards&as=grid&order=name"
        "<a href=\"#{scryfall_url}\">#{card_name}</a>"
      end
      
      paragraph.inner_html = new_html
    end
  end
end
