every 1.day, at: '2:00 pm' do
  runner "Scheduled.send_class_text"
end

every 1.day, at: "9:10 pm" do
  runner "Scheduled.send_summary(1)"
end

every :saturday, at: "9:30 pm" do
  runner "Scheduled.send_summary(7)"
end

every 1.day, at: "9:10 am" do
  runner "Scheduled.attend_random_classes"
end
