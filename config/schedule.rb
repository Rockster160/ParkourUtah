every 1.day, at: '4:00 pm' do
  runner "Event.first.send_text"
end
