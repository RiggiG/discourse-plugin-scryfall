# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::CardHandler do
  describe ".process_raw_content" do
    context "when content has no card syntax" do
      it "returns the content unchanged" do
        raw = "This is a post without any card references."
        expect(described_class.process_raw_content(raw)).to eq(raw)
      end
    end

    context "when content has [[card name]] syntax" do
      it "replaces single card reference with Scryfall URL" do
        raw = "Check out [[Lightning Bolt]]!"
        result = described_class.process_raw_content(raw)
        
        expect(result).to match(%r{https://scryfall\.com/(?:search|card)})
        expect(result).to include("Lightning")
        expect(result).to include("Bolt")
      end

      it "replaces multiple card references" do
        raw = "[[Lightning Bolt]] and [[Sol Ring]] are powerful."
        result = described_class.process_raw_content(raw)
        
        expect(result.scan(/scryfall\.com/).size).to eq(2)
      end

      it "handles card names with special characters" do
        raw = "[[Jace, the Mind Sculptor]] is strong."
        result = described_class.process_raw_content(raw)
        
        expect(result).to include("Jace")
        expect(result).to match(%r{https://scryfall\.com/(?:search|card)})
      end

      it "preserves surrounding text" do
        raw = "Before [[Lightning Bolt]] after"
        result = described_class.process_raw_content(raw)
        
        expect(result).to start_with("Before ")
        expect(result).to end_with(" after")
      end

      it "handles empty card name gracefully" do
        raw = "Empty [[ ]] reference"
        result = described_class.process_raw_content(raw)
        
        expect(result).to match(%r{https://scryfall\.com/(?:search|card)})
      end
    end

    context "when content is nil" do
      it "returns nil" do
        expect(described_class.process_raw_content(nil)).to be_nil
      end
    end

    context "when content is empty string" do
      it "returns empty string" do
        expect(described_class.process_raw_content("")).to eq("")
      end
    end
  end

  describe ".scryfall_url" do
    it "generates a Scryfall search URL" do
      url = described_class.scryfall_url("Lightning Bolt")
      
      expect(url).to match(%r{^https://scryfall\.com/(?:search|card)})
    end

    it "URL encodes the card name" do
      url = described_class.scryfall_url("Jace, the Mind Sculptor")
      
      expect(url).to include("Jace")
      expect(url).not_to include(" ")
    end

    context "with FinalDestination resolution" do
      before do
        # Stub FinalDestination to avoid actual HTTP requests
        allow_any_instance_of(FinalDestination).to receive(:resolve).and_return(nil)
      end

      it "attempts to resolve the search URL" do
        expect(FinalDestination).to receive(:new).and_call_original
        described_class.scryfall_url("Lightning Bolt")
      end

      it "falls back to search URL if resolution fails" do
        url = described_class.scryfall_url("Lightning Bolt")
        expect(url).to match(%r{scryfall\.com/(?:search|card)})
      end
    end

    context "when FinalDestination resolves to card URL" do
      let(:card_url) { "https://scryfall.com/card/clu/141/lightning-bolt" }

      before do
        allow_any_instance_of(FinalDestination).to receive(:resolve)
          .and_return(URI.parse(card_url))
      end

      it "returns the resolved card URL" do
        url = described_class.scryfall_url("Lightning Bolt")
        expect(url).to eq(card_url)
      end
    end
  end
end
