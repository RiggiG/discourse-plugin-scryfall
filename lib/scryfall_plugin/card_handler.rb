# frozen_string_literal: true

require 'cgi'

module ::ScryfallPlugin
  class CardHandler
    def self.process_raw_content(raw_content)
      return raw_content unless raw_content&.match?(/\\*?\[\\*?\[/)
      
      Rails.logger.info "Scryfall: Processing raw content with [[ syntax: #{raw_content.inspect}"
      
      raw_content.gsub(/\\*?\[\\*?\[([^\\\]]+?)\\*\]\\*\]/) do |match|
        card_name = $1.strip
        encoded_name = CGI.escape(card_name)
        scryfall_url = "https://scryfall.com/search?q=#{encoded_name}&unique=cards&as=grid&order=name"
        
        Rails.logger.info "Scryfall: Transforming #{match} (card: #{card_name}) -> #{scryfall_url}"
        
        # Replace with just the URL so Discourse's onebox handles it
        scryfall_url
      end
    end
  end
end