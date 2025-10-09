
# frozen_string_literal: true

require 'cgi'

module ::ScryfallPlugin
  class CardHandler
    def self.process_links(fragment)
      new.process_links(fragment)
    end
    
    def process_links(fragment)
      fragment.css('p').each do |paragraph|
        next if !paragraph.content.include?('[[')
        
        # Process each card reference
        paragraph.inner_html = paragraph.inner_html.gsub(/\[\[([^\]]+)\]\]/) do |match|
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
    
    def create_onebox_link(fragment, paragraph, card_name)
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
end