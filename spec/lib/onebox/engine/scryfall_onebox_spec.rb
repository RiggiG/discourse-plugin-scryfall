# frozen_string_literal: true

require "rails_helper"

describe Onebox::Engine::ScryfallOnebox do
  before do
    @link = "https://scryfall.com/search?q=Lightning+Bolt"
    stub_request(:get, @link).to_return(
      status: 200,
      body: onebox_response("scryfall_search")
    )
  end

  describe ".matches_regexp" do
    it "matches scryfall.com search URLs" do
      expect(described_class.matches_regexp.match("https://scryfall.com/search?q=Lightning+Bolt")).not_to be_nil
    end

    it "matches scryfall.com card URLs" do
      expect(described_class.matches_regexp.match("https://scryfall.com/card/lea/161/lightning-bolt")).not_to be_nil
    end

    it "matches www.scryfall.com URLs" do
      expect(described_class.matches_regexp.match("https://www.scryfall.com/search?q=Sol+Ring")).not_to be_nil
    end

    it "does not match other scryfall.com paths" do
      expect(described_class.matches_regexp.match("https://scryfall.com/sets")).to be_nil
    end

    it "does not match non-scryfall URLs" do
      expect(described_class.matches_regexp.match("https://example.com/search")).to be_nil
    end
  end

  describe ".priority" do
    it "has higher priority than allowlisted generic" do
      expect(described_class.priority).to be < 200
    end
  end

  describe "#to_html" do
    it "includes the scryfall-onebox class" do
      onebox = described_class.new(@link)
      expect(onebox.to_html).to include("scryfall-onebox")
    end

    it "includes the card image" do
      onebox = described_class.new(@link)
      expect(onebox.to_html).to include("scryfall-card-image")
    end

    it "includes the Scryfall favicon" do
      onebox = described_class.new(@link)
      expect(onebox.to_html).to include("scryfall.com/favicon.ico")
    end

    it "returns nil if OpenGraph data is missing" do
      stub_request(:get, @link).to_return(
        status: 200,
        body: "<html><head></head><body>No OpenGraph</body></html>"
      )
      onebox = described_class.new(@link)
      expect(onebox.to_html).to be_nil
    end
  end

  describe "#placeholder_html" do
    it "includes the scryfall-card-link class" do
      onebox = described_class.new(@link)
      expect(onebox.placeholder_html).to include("scryfall-card-link")
    end

    it "includes data attributes for tooltip" do
      onebox = described_class.new(@link)
      html = onebox.placeholder_html
      expect(html).to include("data-card-name")
      expect(html).to include("data-card-image")
      expect(html).to include("data-card-description")
    end

    it "uses the OpenGraph title as link text" do
      onebox = described_class.new(@link)
      html = onebox.placeholder_html
      expect(html).to include(">Lightning Bolt<")
    end

    it "escapes HTML in attributes" do
      malicious_link = "https://scryfall.com/search?q=test"
      stub_request(:get, malicious_link).to_return(
        status: 200,
        body: onebox_response("scryfall_malicious")
      )
      onebox = described_class.new(malicious_link)
      html = onebox.placeholder_html
      expect(html).not_to include("<script>")
      expect(html).to include("&lt;script&gt;")
    end
  end
end

def onebox_response(filename)
  File.read("#{Rails.root}/plugins/discourse-plugin-scryfall/spec/fixtures/onebox/#{filename}.html")
end