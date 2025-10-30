# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::InlineCustomizer do
  let(:fragment) { Nokogiri::HTML5.fragment(html) }

  before do
    SiteSetting.scryfall_plugin_enabled = true
  end

  describe ".customize_inline_oneboxes" do
    context "with Scryfall inline onebox containing full onebox text" do
      let(:html) do
        <<~HTML
          <p>Check out this 
          <a href="https://scryfall.com/card/clu/141/lightning-bolt" class="inline-onebox">
            Lightning Bolt · Clue Edition (CLU) #141 · Scryfall Magic
          </a>
          </p>
        HTML
      end

      it "adds the scryfall-card-link class" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
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

    context "with Scryfall inline onebox containing simple text" do
      let(:html) do
        <<~HTML
          <a href="https://scryfall.com/card/ema/57/jace-the-mind-sculptor" class="inline-onebox">
            Jace, the Mind Sculptor
          </a>
        HTML
      end

      it "preserves the simple card name" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link.inner_html).to eq("Jace, the Mind Sculptor")
      end

      it "adds the custom class and data attribute" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
        expect(link["data-card-url"]).to eq("https://scryfall.com/card/ema/57/jace-the-mind-sculptor")
      end
    end

    context "with Scryfall inline onebox extracting from URL" do
      let(:html) do
        <<~HTML
          <a href="https://scryfall.com/card/cmm/395/sol-ring" class="inline-onebox">
            scryfall.com
          </a>
        HTML
      end

      it "extracts card name from URL" do
        described_class.customize_inline_oneboxes(fragment)
        link = fragment.at_css("a")
        
        expect(link.inner_html).to eq("Sol Ring")
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

    context "with multiple inline oneboxes" do
      let(:html) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/a/1/test-card-1" class="inline-onebox">Test Card 1 · Set</a>
            <a href="https://example.com" class="inline-onebox">Example</a>
            <a href="https://scryfall.com/card/b/2/test-card-2" class="inline-onebox">Test Card 2 · Set</a>
          </p>
        HTML
      end

      it "only modifies Scryfall links" do
        described_class.customize_inline_oneboxes(fragment)
        links = fragment.css("a")
        
        expect(links[0]["class"]).to eq("inline-onebox scryfall-card-link")
        expect(links[1]["class"]).to eq("inline-onebox")
        expect(links[2]["class"]).to eq("inline-onebox scryfall-card-link")
      end

      it "customizes each Scryfall link independently" do
        described_class.customize_inline_oneboxes(fragment)
        links = fragment.css("a")
        
        expect(links[0].inner_html).to eq("Test Card 1")
        expect(links[1].inner_html).to eq("Example")
        expect(links[2].inner_html).to eq("Test Card 2")
      end
    end

    context "when plugin is disabled" do
      let(:html) do
        <<~HTML
          <a href="https://scryfall.com/card/test/1/card" class="inline-onebox">Card</a>
        HTML
      end

      before do
        SiteSetting.scryfall_plugin_enabled = false
      end

      it "does not modify links" do
        original_html = fragment.to_html
        described_class.customize_inline_oneboxes(fragment)
        
        expect(fragment.to_html).to eq(original_html)
      end
    end

    context "when modifying a fragment" do
      let(:html) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/clu/141/lightning-bolt" class="inline-onebox">
              Lightning Bolt · Set
            </a>
          </p>
        HTML
      end

      it "modifies the fragment object in place" do
        # Get HTML before customization
        html_before = fragment.to_html
        
        # Customize
        described_class.customize_inline_oneboxes(fragment)
        
        # Get HTML after customization
        html_after = fragment.to_html
        
        # Verify they're different
        expect(html_after).not_to eq(html_before)
        expect(html_after).to include("scryfall-card-link")
        expect(html_after).to include("data-card-url")
        expect(html_after).not_to include("· Set")
      end
    end
  end
end
