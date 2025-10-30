# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scryfall Plugin Integration" do
  fab!(:user)
  fab!(:topic)

  before do
    SiteSetting.scryfall_plugin_enabled = true
    sign_in(user)
    # Stub FinalDestination to return card URLs
    allow(FinalDestination).to receive(:new) do |search_url, **_opts|
      resolved_uri = case search_url
      when /Lightning\+Bolt/
        URI.parse("https://scryfall.com/card/clu/141/lightning-bolt")
      when /Sol\+Ring/
        URI.parse("https://scryfall.com/card/cmm/395/sol-ring")
      else
        nil
      end
      
      instance_double(FinalDestination, resolve: resolved_uri)
    end
  end

  describe "creating a post with card syntax" do
    it "converts [[card name]] to resolved card URL" do
      raw = "Check out [[Lightning Bolt]]!"
      
      post "/posts.json", params: {
        raw: raw,
        topic_id: topic.id
      }
      
      expect(response.status).to eq(200)
      
      json = response.parsed_body
      expect(json["raw"]).to include("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(json["raw"]).not_to include("[[")
    end

    it "creates post with multiple resolved card URLs" do
      raw = "[[Lightning Bolt]] and [[Sol Ring]] are great."
      
      post "/posts.json", params: {
        raw: raw,
        topic_id: topic.id
      }
      
      expect(response.status).to eq(200)
      
      json = response.parsed_body
      expect(json["raw"]).to include("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(json["raw"]).to include("https://scryfall.com/card/cmm/395/sol-ring")
    end
  end

  describe "editing a post with card syntax" do
    fab!(:post_to_edit) { Fabricate(:post, topic: topic, user: user, raw: "Original text") }

    it "processes card syntax during edit" do
      put "/posts/#{post_to_edit.id}.json", params: {
        post: { raw: "Edited with [[Sol Ring]]" }
      }
      
      expect(response.status).to eq(200)
      
      post_to_edit.reload
      expect(post_to_edit.raw).to include("https://scryfall.com/card/cmm/395/sol-ring")
      expect(post_to_edit.raw).not_to include("[[")
    end
  end

  describe "with plugin disabled" do
    before do
      SiteSetting.scryfall_plugin_enabled = false
    end

    it "does not process card syntax" do
      raw = "Check out [[Lightning Bolt]]!"
      
      post "/posts.json", params: {
        raw: raw,
        topic_id: topic.id
      }
      
      expect(response.status).to eq(200)
      
      json = response.parsed_body
      expect(json["raw"]).to eq(raw)
    end
  end
end
