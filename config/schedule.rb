every 1.minute do
  runner "Event.first.send_text"
end
