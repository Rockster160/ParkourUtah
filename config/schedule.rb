every 1.day, at: '2:00 pm' do
  runner "Event.first.send_text"
end

every 1.day, at: "9:10 pm" do
  runner "Event.first.send_summary"
end

every :saturday, at: "9:30 pm" do
  runner "Event.first.send_weekly_summary"
end
