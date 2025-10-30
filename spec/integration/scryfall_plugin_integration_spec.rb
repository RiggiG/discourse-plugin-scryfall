# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scryfall Plugin Integration" do
  fab!(:user)
  fab!(:topic)

  before do
    SiteSetting.scryfall_plugin_enabled = true
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
      raw = "Check out [[Lightning Bolt]]! This is a powerful card."
      
      post_creator = PostCreator.new(
        user,
        raw: raw,
        topic_id: topic.id
      )
      
      created_post = post_creator.create
      
      expect(created_post).to be_valid
      expect(created_post.raw).to include("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(created_post.raw).not_to include("[[")
    end

    it "creates post with multiple resolved card URLs" do
      raw = "[[Lightning Bolt]] and [[Sol Ring]] are great cards."
      
      post_creator = PostCreator.new(
        user,
        raw: raw,
        topic_id: topic.id
      )
      
      created_post = post_creator.create
      
      expect(created_post).to be_valid
      expect(created_post.raw).to include("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(created_post.raw).to include("https://scryfall.com/card/cmm/395/sol-ring")
    end
  end

  describe "editing a post with card syntax" do
    fab!(:post_to_edit) { Fabricate(:post, topic: topic, user: user, raw: "Original text goes here.") }

    it "processes card syntax during edit" do
      revisor = PostRevisor.new(post_to_edit)
      revisor.revise!(
        user,
        raw: "Edited with [[Sol Ring]] which is powerful."
      )
      
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
      raw = "Check out [[Lightning Bolt]]! This card is powerful."
      
      post_creator = PostCreator.new(
        user,
        raw: raw,
        topic_id: topic.id
      )
      
      created_post = post_creator.create
      
      expect(created_post).to be_valid
      expect(created_post.raw).to eq(raw)
    end
  end
end
