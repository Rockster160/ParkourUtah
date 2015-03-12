every 1.day, at: '4:00 pm' do
  runner "Event.first.send_text"
end

every 1.day, at: '4:00 am' do
  runner "Event.first.send_text"
end
