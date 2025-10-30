# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scryfall Plugin Integration" do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
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

    it "creates cooked HTML with scryfall-card-link class on inline oneboxes" do
      raw = "Check out [[Lightning Bolt]]! This is a powerful card."
      
      post_creator = PostCreator.new(
        user,
        raw: raw,
        topic_id: topic.id
      )
      
      created_post = post_creator.create
      
      expect(created_post).to be_valid
      
      # Trigger post processing (which is normally async)
      Jobs::ProcessPost.new.execute(post_id: created_post.id, new_post: true)
      created_post.reload
      
      # Check that cooked HTML contains our custom class
      doc = Nokogiri::HTML5.fragment(created_post.cooked)
      scryfall_link = doc.at_css('a.scryfall-card-link')
      
      expect(scryfall_link).to be_present, "Expected to find a.scryfall-card-link in:\n#{created_post.cooked}"
      expect(scryfall_link['class']).to include('scryfall-card-link')
      expect(scryfall_link['class']).to include('inline-onebox')
      expect(scryfall_link['href']).to eq("https://scryfall.com/card/clu/141/lightning-bolt")
      expect(scryfall_link.text.strip).to eq("Lightning Bolt")
    end
  end

  describe "editing a post with card syntax" do
    fab!(:post_to_edit) { Fabricate(:post, topic: topic, user: user, raw: "Original text goes here.") }

    it "processes card syntax during edit" do
      new_raw = "Edited with [[Sol Ring]] which is powerful."
      
      revisor = PostRevisor.new(post_to_edit)
      result = revisor.revise!(
        user,
        raw: new_raw
      )
      
      expect(result).to be_truthy
      
      post_to_edit.reload
      expect(post_to_edit.raw).to include("https://scryfall.com/card/cmm/395/sol-ring")
      expect(post_to_edit.raw).not_to include("[[")
      expect(post_to_edit.raw).not_to eq("Original text goes here.")
    end

    it "updates cooked HTML with scryfall-card-link class after edit" do
      new_raw = "Edited with [[Sol Ring]] which is powerful."
      
      revisor = PostRevisor.new(post_to_edit)
      result = revisor.revise!(
        user,
        raw: new_raw
      )
      
      expect(result).to be_truthy
      
      post_to_edit.reload
      
      # Trigger post processing (which is normally async)
      Jobs::ProcessPost.new.execute(post_id: post_to_edit.id)
      post_to_edit.reload
      
      # Check that cooked HTML contains our custom class
      doc = Nokogiri::HTML5.fragment(post_to_edit.cooked)
      scryfall_link = doc.at_css('a.scryfall-card-link')
      
      expect(scryfall_link).to be_present, "Expected to find a.scryfall-card-link in:\n#{post_to_edit.cooked}"
      expect(scryfall_link['class']).to include('scryfall-card-link')
      expect(scryfall_link['class']).to include('inline-onebox')
      expect(scryfall_link['href']).to eq("https://scryfall.com/card/cmm/395/sol-ring")
      expect(scryfall_link.text.strip).to eq("Sol Ring")
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
