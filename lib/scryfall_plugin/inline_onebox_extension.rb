# frozen_string_literal: true

module ScryfallPlugin
  module InlineOneboxExtension
    def onebox_for(url, title = nil, opts = {})
      Rails.logger.error "!!!! SCRYFALL EXTENSION CALLED WITH: #{url}"
      
      # Handle Scryfall search URLs by following redirects
      if url =~ /scryfall\.com\/search/
        begin
          Rails.logger.info "Scryfall: Attempting to resolve search URL: #{url}"
          
          final_url = FinalDestination.new(
            url,
            validate_uri: true,
            max_redirects: 5,
            follow_canonical: false
          ).resolve
          
          Rails.logger.info "Scryfall: FinalDestination returned: #{final_url.inspect}"
          
          # If we got a redirect to a card page, use that instead
          if final_url && final_url.to_s != url && final_url.to_s =~ /scryfall\.com\/card/
            Rails.logger.info "Scryfall: Resolved search URL #{url} to #{final_url}"
            url = final_url.to_s
          else
            Rails.logger.info "Scryfall: No valid card redirect found, using original URL"
          end
        rescue => e
          Rails.logger.error "Scryfall: Failed to resolve redirect: #{e.class} - #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
      
      Rails.logger.info "Scryfall: Calling super with URL: #{url}, title: #{title}, opts: #{opts.inspect}"
      result = super(url, title, opts)
      Rails.logger.info "Scryfall: Super returned: #{result.inspect}"
      result
    end
  end
end