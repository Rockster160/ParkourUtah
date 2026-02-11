require 'rails_helper'

RSpec.describe ContactRequest, type: :model do
  describe "scopes" do
    it ".by_fuzzy_text matches by name" do
      cr = create(:contact_request, name: "Jane Smith")
      create(:contact_request, name: "Bob Jones")
      expect(ContactRequest.by_fuzzy_text("jane")).to include(cr)
    end

    it ".by_fuzzy_text matches by email" do
      cr = create(:contact_request, email: "specific@example.com")
      expect(ContactRequest.by_fuzzy_text("specific")).to include(cr)
    end

    it ".by_fuzzy_text matches by body" do
      cr = create(:contact_request, body: "I want to learn parkour")
      expect(ContactRequest.by_fuzzy_text("parkour")).to include(cr)
    end

    it ".by_fuzzy_text matches by phone" do
      cr = create(:contact_request, phone: "8015551234")
      expect(ContactRequest.by_fuzzy_text("8015551234")).to include(cr)
    end
  end

  describe "#log_message" do
    it "creates a text message from the contact request" do
      cr = create(:contact_request, phone: "8015551234", body: "Help me!")
      room = create(:chat_room, :text_room, name: "8015551234")

      msg = cr.log_message
      expect(msg).to be_a(Message)
      expect(msg.body).to include("Help me!")
    end
  end
end
