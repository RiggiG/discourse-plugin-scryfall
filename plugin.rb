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

require_relative "lib/scryfall_plugin/engine"

after_initialize do
  # Process Scryfall syntax during markdown preprocessing
  on(:reduce_cooked) do |fragment, post|
    if SiteSetting.scryfall_plugin_enabled
      ScryfallPlugin.process_scryfall_links(fragment)
    end
  end

  # Register Onebox provider for Scryfall URLs
  #Onebox.options = Onebox.options.merge({
  #  load_paths: [File.join(Rails.root, "plugins", "discourse-plugin-scryfall", "lib", "onebox")]
  #})
end

module ::ScryfallPlugin
  def self.process_scryfall_links(fragment)
    fragment.css('p').each do |paragraph|
      next if paragraph.content.exclude?('[[')
      
      # Process each card reference
      paragraph.inner_html.gsub!(/\[\[([^\]]+)\]\]/) do |match|
        card_name = $1.strip
        
        case SiteSetting.scryfall_card_display_type
        when 'onebox'
          create_onebox_link(fragment, paragraph, card_name)
        when 'custom'
          # Future: custom card display implementation
          card_name
        else
          card_name
        end
      end
    end
  end
  
  private
  
  def self.create_onebox_link(fragment, paragraph, card_name)
    encoded_name = CGI.escape(card_name)
    scryfall_url = "https://scryfall.com/search?q=#{encoded_name}&unique=cards&as=grid&order=name"
    
    # Insert as new paragraph after current one for proper Onebox processing
    new_p = fragment.document.create_element('p')
    new_p.inner_html = "<a href=\"#{scryfall_url}\" class=\"onebox\" target=\"_blank\">#{scryfall_url}</a>"
    paragraph.add_next_sibling(new_p)
    
    # Replace original with just the card name as text
    card_name
  end
end
