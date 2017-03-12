 # == Schema Information
#
# Table name: chat_room_users
#
#  id                  :integer          not null, primary key
#  chat_room_id        :integer
#  user_id             :integer
#  has_unread_messages :boolean          default(TRUE)
#  notify_via_email    :boolean          default(TRUE)
#  notify_via_css      :boolean          default(FALSE)
#  muted               :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  banned              :boolean          default(FALSE)
#

class ChatRoomUser < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  # (Based on updated at, query to send the user a notification after they have received a message but not read it)
  # Mark unread each time a new message is added to Chat Room

  after_update_commit :broadcast_update

  validates_uniqueness_of :user_id, scope: :chat_room

  private

  def broadcast_update
    # rendered_message = ChatRoomsController.render(partial: 'chat_rooms/index', locals: { chat_rooms: [chat_room] })
    # ActionCable.server.broadcast "rooms_for_user_#{user_id}_channel", message: rendered_message, current_user: nil
  end
end
