# frozen_string_literal: true

module ::ScryfallPlugin
  class InlineCustomizer
    def self.customize_inline_oneboxes(fragment)
      fragment.css('a.inline-onebox').each do |link|
        url = link['href']
        next unless scryfall_url?(url)
        
        # Get onebox data from cache
        onebox_data = Discourse.cache.read(InlineOneboxer.cache_key(url))
        next unless onebox_data
        
        # Extract just the card name from the title
        card_name = extract_card_name(onebox_data[:title])
        
        # Replace with custom rendering: just the card name with special class
        link['class'] = 'scryfall-card-link'
        link['data-card-url'] = url
        link.inner_html = card_name
        
        Rails.logger.info "Scryfall: Customized inline onebox for '#{card_name}'"
      end
    end

    private

    def self.scryfall_url?(url)
      url =~ %r{scryfall\.com/(?:search|card)}
    end

    def self.extract_card_name(title)
      return title unless title
      
      # Title format: "Card Name · Set (CODE) #123 · Scryfall Magic The Gathering Search"
      # Extract just the card name (everything before the first ·)
      if title =~ /^([^·]+)/
        $1.strip
      else
        title
      end
    end
  end
end