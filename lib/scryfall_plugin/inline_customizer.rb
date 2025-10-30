# frozen_string_literal: true

module ::ScryfallPlugin
  class InlineCustomizer
    # This method is called after CookedPostProcessor has finished processing
    # It receives a Nokogiri document object, not HTML string
    def self.customize_inline_oneboxes_in_doc(doc, post)
      return unless SiteSetting.scryfall_plugin_enabled
      return if doc.blank?

      Rails.logger.info "Scryfall: Processing post #{post.id} for inline oneboxes"
      
      # Find all inline oneboxes that are Scryfall links
      doc.css('a.inline-onebox').each do |link|
        url = link['href']
        next unless scryfall_url?(url)
        
        Rails.logger.info "Scryfall: Found inline onebox for URL: #{url}"
        
        # At this point, the link already has the onebox title as its text
        # We want to extract just the card name from it
        current_text = link.text.strip
        
        # The onebox title format is usually: "Card Name · Set Name · Scryfall"
        # Extract just the card name
        card_name = if current_text.include?(' · ')
          current_text.split(' · ')[0].strip
        else
          # Fallback: extract from URL if text doesn't have the expected format
          extract_card_name_from_url(url)
        end
        
        # Add our custom class and update the text to just the card name
        link.add_class('scryfall-card-link')
        link.content = card_name
        
        Rails.logger.info "Scryfall: Customized inline onebox to '#{card_name}'"
      end
    end

    private

    def self.scryfall_url?(url)
      url =~ %r{scryfall\.com/(?:search|card)}
    end

    def self.extract_card_name_from_url(url)
      # Extract from URL
      # URL format: https://scryfall.com/card/set/number/card-name
      if url =~ %r{scryfall\.com/card/[^/]+/[^/]+/(.+)}
        # Convert URL slug back to readable name
        return $1.split('?').first.gsub('-', ' ').split.map(&:capitalize).join(' ')
      end
      
      # Last resort
      'Scryfall Card'
    end
  end
end