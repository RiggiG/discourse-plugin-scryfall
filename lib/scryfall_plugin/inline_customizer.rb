# frozen_string_literal: true

module ::ScryfallPlugin
  class InlineCustomizer
    def self.customize_inline_oneboxes(post, cooked)
      return cooked unless SiteSetting.scryfall_plugin_enabled
      return cooked if cooked.blank?

      fragment = Nokogiri::HTML5.fragment(cooked)
      modified = false
      
      fragment.css('a.inline-onebox, a.inline-onebox-loading').each do |link|
        url = link['href']
        next unless scryfall_url?(url)
        
        Rails.logger.info "Scryfall: Found inline onebox for URL: #{url}"
        
        # Extract card name from the existing link text or URL
        card_name = extract_card_name_from_link(link, url)
        
        # Replace with custom rendering: just the card name with special class
        # Add our custom class while keeping the inline-onebox class
        link.add_class('scryfall-card-link')
        link.inner_html = card_name
        
        Rails.logger.info "Scryfall: Customized inline onebox for '#{card_name}'"
        modified = true
      end

      modified ? fragment.to_html : cooked
    end

    private

    def self.scryfall_url?(url)
      url =~ %r{scryfall\.com/(?:search|card)}
    end

    def self.extract_card_name_from_link(link, url)
      # First try to get it from the existing link text
      current_text = link.inner_text.strip
      
      # If it has the onebox format with · separators, extract the card name
      if current_text.include?('·')
        if current_text =~ /^([^·]+)/
          return $1.strip
        end
      end
      
      # If the link text looks like a real card name (not a URL or domain)
      # Card names have spaces or are multi-word, not just "scryfall.com"
      if current_text.present? && 
         !current_text.include?('.com') && 
         !current_text.include?('.') &&
         current_text != url
        return current_text
      end
      
      # Extract from URL
      # URL format: https://scryfall.com/card/set/number/card-name
      if url =~ %r{scryfall\.com/card/[^/]+/[^/]+/(.+)}
        # Convert URL slug back to readable name
        return $1.split('?').first.gsub('-', ' ').split.map(&:capitalize).join(' ')
      end
      
      # Last resort: use the current text if it exists
      current_text.present? ? current_text : 'Scryfall Card'
    end
  end
end