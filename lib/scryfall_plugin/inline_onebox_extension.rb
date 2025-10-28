# frozen_string_literal: true

module ScryfallPlugin
  module InlineOneboxExtension
    def onebox_for(url)
      # Handle Scryfall search URLs by following redirects
      if url =~ /scryfall\.com\/search/
        begin
          final_url = FinalDestination.new(url, 
            validate_uri: true,
            max_redirects: 5,
            follow_canonical: false
          ).resolve
          
          # If we got a redirect to a card page, use that instead
          if final_url && final_url.to_s != url && final_url.to_s =~ /scryfall\.com\/card/
            Rails.logger.info "Scryfall: Resolved search URL #{url} to #{final_url}"
            url = final_url.to_s
          end
        rescue => e
          Rails.logger.warn("Scryfall: Failed to resolve redirect: #{e.message}")
        end
      end
      
      super(url)
    end
  end
end