require 'rails_helper'

RSpec.describe "Chat Messaging Flow", type: :model do
  describe "chat room messaging" do
    it "creates a room, sends messages, and marks as read" do
      user1 = create(:user, nickname: "Coach")
      user2 = create(:user, nickname: "Student")

      # Create a global chat room
      room = create(:chat_room, name: "General", visibility_level: :global, message_type: :chat)
      chu1 = create(:chat_room_user, chat_room: room, user: user1)
      chu2 = create(:chat_room_user, chat_room: room, user: user2)

      # User1 sends a message
      msg1 = room.messages.create!(body: "Welcome to the group!", sent_from: user1)
      expect(msg1).to be_persisted

      # User2 should have unread messages
      expect(chu2.reload.has_unread_messages).to be true

      # User2 reads it
      msg1.read!
      expect(msg1.read?).to be true

      # User2 replies
      msg2 = room.messages.create!(body: "Thanks coach!", sent_from: user2)
      expect(msg2).to be_persisted
      expect(chu1.reload.has_unread_messages).to be true

      # Check last message
      expect(room.last_message).to eq(msg2)
      expect(room.last_message_text).to eq("Thanks coach!")
    end
  end

  describe "room visibility" do
    it "admin-only rooms are hidden from regular users" do
      admin = create(:user, :admin)
      regular = create(:user)
      instructor = create(:user, :instructor)

      admin_room = create(:chat_room, :admin_only)
      global_room = create(:chat_room, visibility_level: :global)

      admin_visible = ChatRoom.permitted_for_user(admin)
      expect(admin_visible).to include(admin_room, global_room)

      regular_visible = ChatRoom.permitted_for_user(regular)
      expect(regular_visible).to include(global_room)
      expect(regular_visible).not_to include(admin_room)

      instructor_visible = ChatRoom.permitted_for_user(instructor)
      expect(instructor_visible).to include(global_room)
      expect(instructor_visible).not_to include(admin_room)
    end
  end

  describe "message types" do
    it "inherits message_type from chat room" do
      text_room = create(:chat_room, :text_room)
      msg = text_room.messages.create!(body: "Hello via text", sent_from_id: 0)
      expect(msg.message_type).to eq("text")
    end

    it "identifies PKUT system messages" do
      room = create(:chat_room)
      msg = room.messages.create!(body: "System message", sent_from_id: 0)
      expect(msg.from_pkut?).to be true
      expect(msg.sender_name).to eq("ParkourUtah")
    end
  end

  describe "question detection" do
    it "detects questions in messages" do
      room = create(:chat_room)
      user = create(:user)
      q = room.messages.create!(body: "When is the next class?", sent_from: user)
      s = room.messages.create!(body: "See you there", sent_from: user)
      expect(q.question?).to be true
      expect(s.question?).to be false
    end
  end
end
