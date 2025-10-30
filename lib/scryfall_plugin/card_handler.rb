# frozen_string_literal: true

require 'cgi'

module ::ScryfallPlugin
  class CardHandler
    CARD_SYNTAX_REGEX = /\[\[([^\]]+)\]\]/

    def self.process_raw_content(raw_content)
      return raw_content unless raw_content&.include?('[[')
      
      Rails.logger.info "Scryfall: Processing raw content with [[ syntax"
      
      raw_content.gsub(CARD_SYNTAX_REGEX) do |match|
        card_name = $1.strip
        scryfall_url(card_name)
      end
    end

    def self.scryfall_url(card_name)
      encoded_name = CGI.escape(card_name)
      search_url = "https://scryfall.com/search?q=#{encoded_name}&unique=cards&as=grid&order=name"
      
      # Try to resolve to actual card URL for better onebox performance
      resolved_url = resolve_to_card_url(search_url)
      
      Rails.logger.info "Scryfall: [[#{card_name}]] -> #{resolved_url || search_url}"
      
      resolved_url || search_url
    end

    private

    def self.resolve_to_card_url(search_url)
      require 'final_destination'
      
      begin
        final_url = FinalDestination.new(
          search_url,
          validate_uri: true,
          max_redirects: 5,
          follow_canonical: false
        ).resolve
        
        if final_url && final_url.to_s =~ %r{scryfall\.com/card/}
          return final_url.to_s
        end
      rescue => e
        Rails.logger.warn "Scryfall: Failed to resolve card URL: #{e.message}"
      end
      
      nil
    end
  end
end