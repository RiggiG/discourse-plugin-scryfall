# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::InlineCustomizer do
  let(:fragment) { Nokogiri::HTML5.fragment(html) }

  describe ".customize_inline_oneboxes" do
    context "with Scryfall inline onebox" do
      let(:html) do
        <<~HTML
          <p>Check out this 
          <a href="https://scryfall.com/card/clu/141/lightning-bolt" class="inline-onebox">
            Lightning Bolt · Set (CLU) #141 · Scryfall Magic
          </a>
          </p>
        HTML
      end

      before do
        # Mock the onebox cache
        onebox_data = {
          url: "https://scryfall.com/card/clu/141/lightning-bolt",
          title: "Lightning Bolt · Clue Edition (CLU) #141 · Scryfall Magic The Gathering Search"
        }
        allow(Discourse.cache).to receive(:read)
          .with(InlineOneboxer.cache_key("https://scryfall.com/card/clu/141/lightning-bolt"))
          .and_return(onebox_data)
      end

      it "adds the scryfall-card-link class" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link["class"]).to eq("scryfall-card-link")
      end

      it "adds data-card-url attribute" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link["data-card-url"]).to eq("https://scryfall.com/card/clu/141/lightning-bolt")
      end

      it "replaces content with just the card name" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link.inner_html).to eq("Lightning Bolt")
        expect(link.inner_html).not_to include("Clue Edition")
        expect(link.inner_html).not_to include("#141")
      end

      it "preserves the href" do
        original_href = fragment.at_css("a")["href"]
        described_class.customize_inline_oneboxes(fragment)
        
        expect(fragment.at_css("a")["href"]).to eq(original_href)
      end
    end

    context "with non-Scryfall inline onebox" do
      let(:html) do
        <<~HTML
          <a href="https://example.com" class="inline-onebox">Example Site</a>
        HTML
      end

      it "does not modify the link" do
        original_html = fragment.to_html
        described_class.customize_inline_oneboxes(fragment)
        
        expect(fragment.to_html).to eq(original_html)
      end
    end

    context "without onebox cache data" do
      let(:html) do
        <<~HTML
          <a href="https://scryfall.com/card/test" class="inline-onebox">Test</a>
        HTML
      end

      before do
        allow(Discourse.cache).to receive(:read).and_return(nil)
      end

      it "does not modify the link" do
        original_html = fragment.to_html
        described_class.customize_inline_oneboxes(fragment)
        
        expect(fragment.to_html).to eq(original_html)
      end
    end

    context "with multiple inline oneboxes" do
      let(:html) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/a/1/test1" class="inline-onebox">Card 1 · Set</a>
            <a href="https://example.com" class="inline-onebox">Example</a>
            <a href="https://scryfall.com/card/b/2/test2" class="inline-onebox">Card 2 · Set</a>
          </p>
        HTML
      end

      before do
        allow(Discourse.cache).to receive(:read).and_return(
          { url: "test", title: "Card 1 · Set" }
        )
      end

      it "only modifies Scryfall links" do
        described_class.customize_inline_oneboxes(fragment)
        links = fragment.css("a")
        
        expect(links[0]["class"]).to eq("scryfall-card-link")
        expect(links[1]["class"]).to eq("inline-onebox")
        expect(links[2]["class"]).to eq("scryfall-card-link")
      end
    end
  end

  describe ".extract_card_name" do
    it "extracts card name from standard Scryfall title" do
      title = "Lightning Bolt · Clue Edition (CLU) #141 · Scryfall Magic The Gathering Search"
      result = described_class.send(:extract_card_name, title)
      
      expect(result).to eq("Lightning Bolt")
    end

    it "handles title with no set information" do
      title = "Lightning Bolt"
      result = described_class.send(:extract_card_name, title)
      
      expect(result).to eq("Lightning Bolt")
    end

    it "returns title if nil" do
      result = described_class.send(:extract_card_name, nil)
      
      expect(result).to be_nil
    end

    it "strips whitespace from extracted name" do
      title = "  Sol Ring  · Set"
      result = described_class.send(:extract_card_name, title)
      
      expect(result).to eq("Sol Ring")
    end
  end
end
