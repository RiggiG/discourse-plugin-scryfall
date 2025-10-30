# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::InlineCustomizer do
  fab!(:post)

  before { SiteSetting.scryfall_plugin_enabled = true }

  describe ".customize_inline_oneboxes" do
    context "with Scryfall inline onebox using full title format" do
      let(:cooked) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/ema/57/jace-the-mind-sculptor" class="inline-onebox">
              Jace, the Mind Sculptor · Eternal Masters (EMA) #57 · Scryfall Magic The Gathering Search
            </a>
          </p>
        HTML
      end

      it "extracts just the card name" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        link = doc.at_css("a")

        expect(link.inner_html).to eq("Jace, the Mind Sculptor")
      end

      it "adds the custom class and data attribute" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        link = doc.at_css("a")

        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
        expect(link["data-card-url"]).to eq("https://scryfall.com/card/ema/57/jace-the-mind-sculptor")
      end
    end

    context "with Scryfall inline onebox using simple card name" do
      let(:cooked) do
        <<~HTML
          <a href="https://scryfall.com/card/ema/57/jace-the-mind-sculptor" class="inline-onebox">
            Jace, the Mind Sculptor
          </a>
        HTML
      end

      it "preserves the simple card name" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        link = doc.at_css("a")

        expect(link.inner_html).to eq("Jace, the Mind Sculptor")
      end

      it "adds the custom class and data attribute" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        link = doc.at_css("a")

        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
        expect(link["data-card-url"]).to eq("https://scryfall.com/card/ema/57/jace-the-mind-sculptor")
      end
    end

    context "with Scryfall inline onebox extracting from URL" do
      let(:cooked) do
        <<~HTML
          <a href="https://scryfall.com/card/cmm/395/sol-ring" class="inline-onebox">
            scryfall.com
          </a>
        HTML
      end

      it "extracts card name from URL" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        link = doc.at_css("a")

        expect(link.inner_html).to eq("Sol Ring")
      end
    end

    context "with non-Scryfall inline onebox" do
      let(:cooked) do
        <<~HTML
          <a href="https://example.com" class="inline-onebox">Example Site</a>
        HTML
      end

      it "does not modify the link" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        
        expect(result).to eq(cooked)
      end
    end

    context "with multiple inline oneboxes" do
      let(:cooked) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/a/1/test-card-1" class="inline-onebox">Test Card 1 · Set</a>
            <a href="https://example.com" class="inline-onebox">Example</a>
            <a href="https://scryfall.com/card/b/2/test-card-2" class="inline-onebox">Test Card 2 · Set</a>
          </p>
        HTML
      end

      it "only modifies Scryfall links" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        links = doc.css("a")

        expect(links[0]["class"]).to eq("inline-onebox scryfall-card-link")
        expect(links[1]["class"]).to eq("inline-onebox")
        expect(links[2]["class"]).to eq("inline-onebox scryfall-card-link")
      end

      it "customizes each Scryfall link independently" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        doc = Nokogiri::HTML5.fragment(result)
        links = doc.css("a")

        expect(links[0].inner_html).to eq("Test Card 1")
        expect(links[1].inner_html).to eq("Example")
        expect(links[2].inner_html).to eq("Test Card 2")
      end
    end

    context "when plugin is disabled" do
      let(:cooked) do
        <<~HTML
          <a href="https://scryfall.com/card/test/1/card" class="inline-onebox">Card</a>
        HTML
      end

      before { SiteSetting.scryfall_plugin_enabled = false }

      it "does not modify links" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        
        expect(result).to eq(cooked)
      end
    end

    context "when cooked HTML is blank" do
      it "returns the blank cooked value" do
        result = described_class.customize_inline_oneboxes(post, "")
        expect(result).to eq("")

        result = described_class.customize_inline_oneboxes(post, nil)
        expect(result).to be_nil
      end
    end

    context "when modifying HTML" do
      let(:cooked) do
        <<~HTML
          <p>
            <a href="https://scryfall.com/card/clu/141/lightning-bolt" class="inline-onebox">
              Lightning Bolt · Set
            </a>
          </p>
        HTML
      end

      it "returns modified HTML when changes are made" do
        result = described_class.customize_inline_oneboxes(post, cooked)
        
        expect(result).not_to eq(cooked)
        expect(result).to include("scryfall-card-link")
        expect(result).to include("data-card-url")
        expect(result).not_to include("· Set")
      end

      it "only returns modified HTML if changes were actually made" do
        non_scryfall_cooked = '<a href="https://example.com" class="inline-onebox">Example</a>'
        result = described_class.customize_inline_oneboxes(post, non_scryfall_cooked)
        
        # Should return original cooked since no modifications were made
        expect(result).to eq(non_scryfall_cooked)
      end
    end
  end
end
