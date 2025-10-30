# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::CardHandler do
  # Default: stub FinalDestination to return card URLs
  before do
    # Mock FinalDestination.new to return a verifying double with resolve method
    allow(FinalDestination).to receive(:new) do |search_url, **_opts|
      resolved_uri = case search_url
      when /Lightning\+Bolt/
        URI.parse("https://scryfall.com/card/clu/141/lightning-bolt")
      when /Sol\+Ring/
        URI.parse("https://scryfall.com/card/cmm/395/sol-ring")
      when /Jace.*Mind\+Sculptor/
        URI.parse("https://scryfall.com/card/ema/57/jace-the-mind-sculptor")
      else
        # Return nil for other cases (will fall back to search URL)
        nil
      end
      
      instance_double(FinalDestination, resolve: resolved_uri)
    end
  end

  describe ".process_raw_content" do
    context "when content has no card syntax" do
      it "returns the content unchanged" do
        raw = "This is a post without any card references."
        expect(described_class.process_raw_content(raw)).to eq(raw)
      end
    end

    context "when content has [[card name]] syntax" do
      it "replaces single card reference with resolved card URL" do
        raw = "Check out [[Lightning Bolt]]!"
        result = described_class.process_raw_content(raw)
        
        expect(result).to include("https://scryfall.com/card/clu/141/lightning-bolt")
        expect(result).not_to include("[[")
      end

      it "replaces multiple card references with resolved URLs" do
        raw = "[[Lightning Bolt]] and [[Sol Ring]] are powerful."
        result = described_class.process_raw_content(raw)
        
        expect(result).to include("https://scryfall.com/card/clu/141/lightning-bolt")
        expect(result).to include("https://scryfall.com/card/cmm/395/sol-ring")
      end

      it "handles card names with special characters" do
        raw = "[[Jace, the Mind Sculptor]] is strong."
        result = described_class.process_raw_content(raw)
        
        expect(result).to include("https://scryfall.com/card/ema/57/jace-the-mind-sculptor")
      end

      it "preserves surrounding text" do
        raw = "Before [[Lightning Bolt]] after"
        result = described_class.process_raw_content(raw)
        
        expect(result).to start_with("Before ")
        expect(result).to end_with(" after")
        expect(result).to include("/card/")
      end

      it "falls back to search URL when resolution fails" do
        raw = "Unknown [[Nonexistent Card Name]] reference"
        result = described_class.process_raw_content(raw)
        
        expect(result).to match(%r{https://scryfall\.com/search})
        expect(result).to include("Nonexistent")
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
    context "when FinalDestination resolves to card URL" do
      let(:card_url) { "https://scryfall.com/card/clu/141/lightning-bolt" }

      it "returns the resolved card URL" do
        url = described_class.scryfall_url("Lightning Bolt")
        expect(url).to eq(card_url)
      end
    end

    context "when FinalDestination resolution fails" do
      before do
        # Override default stub to return nil
        allow_any_instance_of(FinalDestination).to receive(:resolve).and_return(nil)
      end

      it "falls back to search URL" do
        url = described_class.scryfall_url("Unknown Card")
        expect(url).to match(%r{^https://scryfall\.com/search})
        expect(url).to include("Unknown")
      end

      it "URL encodes the card name in search URL" do
        url = described_class.scryfall_url("Card With Spaces")
        expect(url).to include("Card")
        expect(url).not_to include(" ")
        expect(url).to match(/With/)
      end
    end

    it "attempts to resolve using FinalDestination" do
      described_class.scryfall_url("Lightning Bolt")
      expect(FinalDestination).to have_received(:new)
    end
  end
end
