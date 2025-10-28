# frozen_string_literal: true

module Onebox
  module Engine
    class ScryfallOnebox
      include Engine
      include StandardEmbed

      matches_regexp(/^https?:\/\/scryfall\.com\/search\?q=(.+?)(?:&|$)/)

      always_https

      def self.priority
        0
      end

      def to_html
        # Full onebox version (for standalone links)
        og = get_opengraph
        
        return nil unless og&.title && og.image

        <<~HTML
          <aside class="onebox scryfall-onebox" data-onebox-src="#{url}">
            <header class="source">
              <img src="https://scryfall.com/favicon.ico" class="site-icon" width="16" height="16">
              <a href="#{url}" target="_blank" rel="noopener nofollow ugc">Scryfall</a>
            </header>
            <article class="onebox-body">
              <div class="scryfall-card-container">
                <img src="#{og.image}" class="scryfall-card-image" alt="#{escape_attribute(og.title)}">
              </div>
            </article>
          </aside>
        HTML
      end

      def placeholder_html
        # Inline version with embedded card data from OpenGraph
        og = get_opengraph
        
        return nil unless og&.title

        # Embed all the OpenGraph data as data attributes for tooltips
        # Use the search query as the link text to preserve [[Card Name]]
        <<~HTML
          <a href="#{url}" 
             class="scryfall-card-link" 
             data-card-name="#{escape_attribute(og.title)}"
             data-card-image="#{escape_attribute(og.image || '')}"
             data-card-description="#{escape_attribute(og.description || '')}">#{escape_attribute(search_query)}</a>
        HTML
      end

      private

      def search_query
        @search_query ||= begin
          # Extract the query parameter and decode it
          URI.decode_www_form_component(match[1])
        rescue => e
          Rails.logger.warn("Scryfall: Failed to decode search query: #{e.message}")
          "Card"
        end
      end

      def escape_attribute(text)
        ERB::Util.html_escape(text.to_s)
      end
    end
  end
end