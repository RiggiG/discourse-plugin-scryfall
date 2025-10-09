# frozen_string_literal: true

require 'cgi'

module ::ScryfallPlugin
  class CardHandler
    def self.process_links(fragment)
      new.process_links(fragment)
    end
    
    def process_links(fragment)
      Rails.logger.info "Scryfall: Processing fragment with #{fragment.css('p').length} paragraphs"
      
      fragment.css('p').each do |paragraph|
        content = paragraph.content
        next if content.exclude?('[[')
        
        Rails.logger.info "Scryfall: Found paragraph with [[: #{content}"
        
        # Process each card reference
        new_html = paragraph.inner_html.gsub(/\[\[([^\]]+)\]\]/) do |match|
          card_name = $1.strip
          Rails.logger.info "Scryfall: Processing card: #{card_name}"
          
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
        
        paragraph.inner_html = new_html
      end
    end
    
    private
    
    def create_onebox_link(fragment, paragraph, card_name)
      encoded_name = CGI.escape(card_name)
      scryfall_url = "https://scryfall.com/search?q=#{encoded_name}&unique=cards&as=grid&order=name"
      
      Rails.logger.info "Scryfall: Creating onebox for #{card_name} -> #{scryfall_url}"
      
      # Insert as new paragraph after current one for proper Onebox processing
      new_p = fragment.document.create_element('p')
      new_p.inner_html = "<a href=\"#{scryfall_url}\" class=\"onebox\" target=\"_blank\">#{scryfall_url}</a>"
      paragraph.add_next_sibling(new_p)
      
      # Replace original with just the card name as text
      card_name
    end
  end
end