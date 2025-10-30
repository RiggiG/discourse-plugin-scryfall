# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::PostRevisorExtension do
  fab!(:user)
  fab!(:post) { Fabricate(:post, user: user) }

  before do
    SiteSetting.scryfall_plugin_enabled = true
  end

  describe "post revision" do
    it "processes card syntax when editing a post" do
      revisor = PostRevisor.new(post)
      new_raw = "Check out [[Lightning Bolt]]"
      
      revisor.revise!(user, raw: new_raw)
      
      expect(post.raw).to match(%r{scryfall\.com/(?:search|card)})
      expect(post.raw).not_to include("[[")
    end

    it "does not modify content without card syntax" do
      revisor = PostRevisor.new(post)
      new_raw = "This is just regular text."
      
      revisor.revise!(user, raw: new_raw)
      
      expect(post.raw).to eq(new_raw)
    end

    it "works when plugin is disabled" do
      SiteSetting.scryfall_plugin_enabled = false
      revisor = PostRevisor.new(post)
      new_raw = "Check out [[Lightning Bolt]]"
      
      revisor.revise!(user, raw: new_raw)
      
      expect(post.raw).to eq(new_raw)
    end

    it "handles multiple card references in edit" do
      revisor = PostRevisor.new(post)
      new_raw = "[[Lightning Bolt]] and [[Sol Ring]]"
      
      revisor.revise!(user, raw: new_raw)
      
      expect(post.raw.scan(/scryfall\.com/).size).to eq(2)
    end
  end
end
