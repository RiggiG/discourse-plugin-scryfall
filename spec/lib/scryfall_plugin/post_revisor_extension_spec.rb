# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallPlugin::PostRevisorExtension do
  fab!(:user)
  fab!(:post) { Fabricate(:post, user: user) }

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

  describe "post revision" do
    it "processes card syntax when editing a post" do
      revisor = PostRevisor.new(post)
      new_raw = "Check out [[Lightning Bolt]]"
      
      revisor.revise!(user, raw: new_raw)
      
      expect(post.raw).to include("https://scryfall.com/card/clu/141/lightning-bolt")
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
      
      expect(post.raw).to include("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(post.raw).to include("https://scryfall.com/card/cmm/395/sol-ring")
    end
  end
end
