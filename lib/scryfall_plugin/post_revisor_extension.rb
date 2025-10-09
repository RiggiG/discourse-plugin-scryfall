# frozen_string_literal: true

module ::ScryfallPlugin
  module PostRevisorExtension
    def revise!(editor, fields, opts = {})
      if SiteSetting.scryfall_plugin_enabled && fields.key?(:raw)
        Rails.logger.info "Scryfall: Processing raw content during revision"
        original_raw = fields[:raw]
        processed_raw = ScryfallPlugin::CardHandler.process_raw_content(original_raw)
        if processed_raw != original_raw
          Rails.logger.info "Scryfall: Raw content modified during revision"
          fields[:raw] = processed_raw
        end
      end
      
      super(editor, fields, opts)
    end
  end
end