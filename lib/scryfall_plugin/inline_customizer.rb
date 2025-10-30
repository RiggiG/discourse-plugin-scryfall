# frozen_string_literal: true

module ::ScryfallPlugin
  class InlineCustomizer
    def self.customize_inline_oneboxes(fragment)
      return unless SiteSetting.scryfall_plugin_enabled
      
      fragment.css('a.inline-onebox').each do |link|
        url = link['href']
        next unless scryfall_url?(url)
        
        Rails.logger.info "Scryfall: Found inline onebox for URL: #{url}"
        
        # Extract card name from the existing link text or URL
        card_name = extract_card_name_from_link(link, url)
        
        # Replace with custom rendering: just the card name with special class
        # Add our custom class while keeping the inline-onebox class
        link.add_class('scryfall-card-link')
        link['data-card-url'] = url
        link.inner_html = card_name
        
        Rails.logger.info "Scryfall: Customized inline onebox for '#{card_name}'"
      end
    end

    private

    def self.scryfall_url?(url)
      url =~ %r{scryfall\.com/(?:search|card)}
    end

    def self.extract_card_name_from_link(link, url)
      # First try to get it from the existing link text
      current_text = link.inner_text.strip
      
      # If the link already has text that looks like a card name
      # (i.e., doesn't look like a full onebox title with · separators)
      if current_text.present? && !current_text.include?('·')
        return current_text
      end
      
      # If it has the onebox format, extract the card name
      if current_text =~ /^([^·]+)/
        return $1.strip
      end
      
      # Fallback: extract from URL
      # URL format: https://scryfall.com/card/set/number/card-name
      if url =~ %r{scryfall\.com/card/[^/]+/[^/]+/(.+)}
        # Convert URL slug back to readable name
        return $1.split('?').first.gsub('-', ' ').split.map(&:capitalize).join(' ')
      end
      
      # Last resort: use the URL text or domain
      current_text.present? ? current_text : 'Scryfall Card'
    end
  end
end