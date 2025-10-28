# frozen_string_literal: true

module Onebox
  module Engine
    class ScryfallOnebox
      include Engine
      include StandardEmbed

      # Match both search URLs and direct card URLs
      matches_regexp(/^https?:\/\/(?:www\.)?scryfall\.com\/(?:search|card)/)

      always_https

      # Higher priority than allowlisted generic (200)
      def self.priority
        50
      end

      def to_html
        Rails.logger.info "Scryfall Onebox: to_html called for #{url}"
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
        Rails.logger.info "Scryfall Onebox: placeholder_html called for #{url}"
        # Inline version with embedded card data from OpenGraph
        og = get_opengraph

        return nil unless og&.title

        # Embed all the OpenGraph data as data attributes for tooltips
        # Use OpenGraph title as the link text
        <<~HTML
          <a href="#{url}"
             class="scryfall-card-link"
             data-card-name="#{escape_attribute(og.title)}"
             data-card-image="#{escape_attribute(og.image || '')}"
             data-card-description="#{escape_attribute(og.description || '')}">#{escape_attribute(og.title)}</a>
        HTML
      end

      private

      def escape_attribute(text)
        ERB::Util.html_escape(text.to_s)
      end
    end
  end
end