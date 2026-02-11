require 'rails_helper'

RSpec.describe Message, type: :model do
  describe "associations" do
    it { should belong_to(:chat_room) }
  end

  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  describe "#read! / #read? / #unread?" do
    it "marks a message as read" do
      msg = create(:message)
      expect(msg.unread?).to be true
      msg.read!
      expect(msg.read?).to be true
      expect(msg.unread?).to be false
    end
  end

  describe "#from_pkut?" do
    it "returns true when sent_from_id is 0" do
      msg = build(:message, :from_pkut)
      expect(msg.from_pkut?).to be true
    end
  end

  describe "#from_admin?" do
    it "returns true when sent from admin user" do
      admin = create(:user, :admin)
      msg = create(:message, sent_from: admin)
      expect(msg.from_admin?).to be true
    end

    it "returns false when sent from regular user" do
      user = create(:user)
      msg = create(:message, sent_from: user)
      expect(msg.from_admin?).to be false
    end
  end

  describe "#question?" do
    it "returns true when body contains question mark" do
      msg = build(:message, body: "How are you?")
      expect(msg.question?).to be true
    end

    it "returns false for statements" do
      msg = build(:message, body: "I am fine")
      expect(msg.question?).to be false
    end
  end

  describe "#sender_name" do
    it "returns 'ParkourUtah' for system messages" do
      msg = build(:message, :from_pkut)
      expect(msg.sender_name).to eq("ParkourUtah")
    end

    it "returns user display name" do
      user = create(:user, nickname: "Flash")
      msg = create(:message, sent_from: user)
      expect(msg.sender_name).to eq("Flash")
    end
  end

  describe "scopes" do
    it ".read returns read messages" do
      read_msg = create(:message, :read)
      unread_msg = create(:message)
      expect(Message.read).to include(read_msg)
      expect(Message.read).not_to include(unread_msg)
    end

    it ".unread returns unread messages" do
      read_msg = create(:message, :read)
      unread_msg = create(:message)
      expect(Message.unread).to include(unread_msg)
      expect(Message.unread).not_to include(read_msg)
    end
  end
end
