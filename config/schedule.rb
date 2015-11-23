every 1.hour do
  runner "Scheduled.send_class_text"
end

every 1.day, at: "9:10 pm" do
  runner "Scheduled.send_summary(1)"
end

every 1.day, at: "9:30 am" do
  runner "Scheduled.waiver_checks"
end

every 1.day, at: "7:00 am" do
  runner "Scheduled.monthly_subscription_charges"
end

every :saturday, at: "9:30 pm" do
  runner "Scheduled.send_summary(7)"
end

every '0 11 5 * *' do
  runner "Scheduled.request_charges"
end

every '0 11 7 * *' do
  runner "Scheduled.give_charges"
end
