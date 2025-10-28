# frozen_string_literal: true

require "rails_helper"

RSpec.describe Onebox::Engine::ScryfallOnebox do
  let(:search_url) { "https://scryfall.com/search?q=Lightning+Bolt" }
  let(:card_url) { "https://scryfall.com/card/lea/161/lightning-bolt" }
  let(:html_body) { onebox_response("scryfall_search") }

  before do
    stub_request(:get, search_url).to_return(status: 200, body: html_body)
    stub_request(:head, search_url).to_return(status: 200)
    stub_request(:get, card_url).to_return(status: 200, body: html_body)
    stub_request(:head, card_url).to_return(status: 200)
  end

  describe "engine selection" do
    it "uses ScryfallOnebox for search URLs instead of generic engine" do
      onebox = Onebox.preview(search_url)
      expect(onebox).to be_a(described_class)
    end

    it "uses ScryfallOnebox for card URLs instead of generic engine" do
      onebox = Onebox.preview(card_url)
      expect(onebox).to be_a(described_class)
    end
  end

  describe "pattern matching" do
    let(:matcher) { described_class.class_variable_get(:@@matcher) }

    it "matches scryfall.com search URLs" do
      expect(matcher).to match("https://scryfall.com/search?q=Lightning+Bolt")
    end

    it "matches scryfall.com card URLs" do
      expect(matcher).to match("https://scryfall.com/card/lea/161/lightning-bolt")
    end

    it "matches www.scryfall.com URLs" do
      expect(matcher).to match("https://www.scryfall.com/search?q=Sol+Ring")
    end

    it "does not match other scryfall.com paths" do
      expect(matcher).not_to match("https://scryfall.com/sets")
    end

    it "does not match non-scryfall URLs" do
      expect(matcher).not_to match("https://example.com/search")
    end
  end

  describe ".priority" do
    it "has higher priority than allowlisted generic" do
      expect(described_class.priority).to be < 200
    end
  end

  describe "#to_html" do
    it "returns HTML content" do
      onebox = Onebox.preview(search_url)
      expect(onebox.to_s).to be_present
    end

    it "includes the scryfall-onebox class" do
      onebox = Onebox.preview(search_url)
      expect(onebox.to_s).to include("scryfall-onebox")
    end

    it "includes the card image" do
      onebox = Onebox.preview(search_url)
      expect(onebox.to_s).to include("scryfall-card-image")
    end

    it "includes the Scryfall favicon" do
      onebox = Onebox.preview(search_url)
      expect(onebox.to_s).to include("scryfall.com/favicon.ico")
    end
  end

  describe "#placeholder_html" do
    it "returns HTML content" do
      onebox = described_class.new(search_url)
      expect(onebox.placeholder_html).to be_present
    end

    it "includes the scryfall-card-link class" do
      onebox = described_class.new(search_url)
      expect(onebox.placeholder_html).to include("scryfall-card-link")
    end

    it "includes data attributes for tooltip" do
      onebox = described_class.new(search_url)
      html = onebox.placeholder_html
      expect(html).to include("data-card-name")
      expect(html).to include("data-card-image")
      expect(html).to include("data-card-description")
    end

    it "uses the OpenGraph title as link text" do
      onebox = described_class.new(search_url)
      expect(onebox.placeholder_html).to include(">Lightning Bolt<")
    end
  end

  def onebox_response(filename)
    File.read(
      "#{Rails.root}/plugins/discourse-plugin-scryfall/spec/fixtures/onebox/#{filename}.html"
    )
  end
end