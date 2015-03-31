every 1.hour do
  runner "Scheduled.send_class_text"
end

every 1.day, at: "9:10 pm" do
  runner "Scheduled.send_summary(1)"
  runner "Scheduled.waiver_checks"
end

every :saturday, at: "9:30 pm" do
  runner "Scheduled.send_summary(7)"
end
