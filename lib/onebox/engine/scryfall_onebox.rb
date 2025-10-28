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

      # Use the standard OpenGraph-based full onebox from StandardEmbed
      # No need to override to_html - the parent does exactly what we want

      def placeholder_html
        # Inline version with embedded card data from OpenGraph for hover tooltips
        og = get_opengraph
        
        return nil unless og&.title

        escaped_url = ::Onebox::Helpers.normalize_url_for_output(url)
        escaped_title = ::Onebox::Helpers.html_escape(og.title)
        escaped_description = ::Onebox::Helpers.html_escape(og.description || "")

        # Embed all the OpenGraph data as data attributes for tooltips
        <<~HTML
          <a href="#{escaped_url}"
             class="scryfall-card-link"
             data-card-name="#{escaped_title}"
             data-card-image="#{og.image}"
             data-card-description="#{escaped_description}">#{escaped_title}</a>
        HTML
      end
    end
  end
end