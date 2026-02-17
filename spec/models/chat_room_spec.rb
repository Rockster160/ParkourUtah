require 'rails_helper'

RSpec.describe ChatRoom, type: :model do
  describe "associations" do
    it { should have_many(:chat_room_users).dependent(:destroy) }
    it { should have_many(:users).through(:chat_room_users) }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe "defaults" do
    it "defaults to admin visibility" do
      room = ChatRoom.new
      expect(room.visibility_level).to eq("admin")
    end

    it "defaults to chat message type" do
      room = ChatRoom.new
      expect(room.message_type).to eq("chat")
    end
  end

  describe "#display_name" do
    it "returns room name for chat rooms" do
      room = create(:chat_room, name: "General Chat")
      expect(room.display_name).to eq("General Chat")
    end

    it "returns user names when no name set" do
      user1 = create(:user, nickname: "Flash")
      user2 = create(:user, nickname: "Runner")
      room = create(:chat_room, name: nil)
      create(:chat_room_user, chat_room: room, user: user1)
      create(:chat_room_user, chat_room: room, user: user2)
      display = room.display_name(user1)
      expect(display).to include("Runner")
    end
  end

  describe "#viewable_by_user?" do
    it "returns true for members" do
      user = create(:user)
      room = create(:chat_room)
      create(:chat_room_user, chat_room: room, user: user)
      expect(room.viewable_by_user?(user)).to be true
    end

    it "returns true for admins even if not a member" do
      admin = create(:user, :admin)
      room = create(:chat_room)
      expect(room.viewable_by_user?(admin)).to be true
    end

    it "returns false for non-members" do
      user = create(:user)
      room = create(:chat_room)
      expect(room.viewable_by_user?(user)).to be false
    end
  end

  describe "scopes" do
    it ".permitted_for_user returns rooms matching user role" do
      admin = create(:user, :admin)
      instructor = create(:user, :instructor)
      admin_room = create(:chat_room, :admin_only)
      global_room = create(:chat_room, visibility_level: :global)

      expect(ChatRoom.permitted_for_user(admin)).to include(admin_room, global_room)
      expect(ChatRoom.permitted_for_user(instructor)).not_to include(admin_room)
      expect(ChatRoom.permitted_for_user(instructor)).to include(global_room)
    end

    it ".permitted_for_user returns none for nil user" do
      expect(ChatRoom.permitted_for_user(nil)).to be_empty
    end
  end

  describe "#last_message" do
    it "returns the most recent message" do
      room = create(:chat_room)
      _old = create(:message, chat_room: room, body: "Old", created_at: 1.hour.ago)
      recent = create(:message, chat_room: room, body: "Recent")
      expect(room.last_message).to eq(recent)
    end
  end

  describe "#blacklisted?" do
    it "returns false for chat rooms" do
      room = create(:chat_room, message_type: :chat)
      expect(room.blacklisted?).to be false
    end
  end
end
