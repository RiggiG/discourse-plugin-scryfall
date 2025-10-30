# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::InlineCustomizer do
  fab!(:post)

  before { SiteSetting.scryfall_plugin_enabled = true }

  describe ".customize_inline_oneboxes_in_doc" do
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
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        link = doc.at_css("a")

        expect(link.text.strip).to eq("Jace, the Mind Sculptor")
      end

      it "adds the custom class" do
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        link = doc.at_css("a")

        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
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
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        link = doc.at_css("a")

        expect(link.text.strip).to eq("Jace, the Mind Sculptor")
      end

      it "adds the custom class" do
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        link = doc.at_css("a")

        expect(link["class"]).to eq("inline-onebox scryfall-card-link")
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
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        link = doc.at_css("a")

        expect(link.text.strip).to eq("Sol Ring")
      end
    end

    context "with non-Scryfall inline onebox" do
      let(:cooked) do
        <<~HTML
          <a href="https://example.com" class="inline-onebox">Example Site</a>
        HTML
      end

      it "does not modify the link" do
        doc = Nokogiri::HTML5.fragment(cooked)
        original_html = doc.to_html
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        
        expect(doc.to_html).to eq(original_html)
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
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        links = doc.css("a")

        expect(links[0]["class"]).to eq("inline-onebox scryfall-card-link")
        expect(links[1]["class"]).to eq("inline-onebox")
        expect(links[2]["class"]).to eq("inline-onebox scryfall-card-link")
      end

      it "customizes each Scryfall link independently" do
        doc = Nokogiri::HTML5.fragment(cooked)
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        links = doc.css("a")

        expect(links[0].text.strip).to eq("Test Card 1")
        expect(links[1].text.strip).to eq("Example")
        expect(links[2].text.strip).to eq("Test Card 2")
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
        doc = Nokogiri::HTML5.fragment(cooked)
        original_html = doc.to_html
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        
        expect(doc.to_html).to eq(original_html)
      end
    end

    context "when doc is blank" do
      it "returns early without error" do
        doc = nil
        expect { described_class.customize_inline_oneboxes_in_doc(doc, post) }.not_to raise_error
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

      it "modifies the document in place when changes are made" do
        doc = Nokogiri::HTML5.fragment(cooked)
        original_html = doc.to_html
        
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        
        expect(doc.to_html).not_to eq(original_html)
        expect(doc.to_html).to include("scryfall-card-link")
        expect(doc.to_html).not_to include("· Set")
      end

      it "does not modify document if no Scryfall links present" do
        non_scryfall_cooked = '<a href="https://example.com" class="inline-onebox">Example</a>'
        doc = Nokogiri::HTML5.fragment(non_scryfall_cooked)
        original_html = doc.to_html
        
        described_class.customize_inline_oneboxes_in_doc(doc, post)
        
        # Should not modify doc since no Scryfall links
        expect(doc.to_html).to eq(original_html)
      end
    end
  end
end
