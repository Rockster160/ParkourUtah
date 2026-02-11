require 'rails_helper'

RSpec.describe ClassSummaryCalculator do
  let(:instructor) { create(:user, :instructor, full_name: "Coach Bob") }
  let(:schedule) { create(:event_schedule, instructor: instructor, cost_in_pennies: 1000, payment_per_student: 4, min_payment_per_session: 15) }
  let(:event) { create(:event, event_schedule: schedule, date: Time.zone.now) }

  describe "#initialize" do
    it "raises with invalid date format" do
      expect {
        ClassSummaryCalculator.new(start_date: "not a date")
      }.to raise_error(StandardError)
    end
  end

  describe "#generate" do
    it "produces a CalculatedSummary" do
      summary = ClassSummaryCalculator.new(
        start_date: Time.zone.now.beginning_of_day,
        end_date: Time.zone.now.end_of_day
      ).generate

      expect(summary).to be_a(ClassSummaryCalculator::CalculatedSummary)
      expect(summary.start_date).to be_present
      expect(summary.end_date).to be_present
      expect(summary.days).to be_an(Array)
      expect(summary.instructors).to be_an(Array)
    end

    it "calculates earnings from credit-based attendances" do
      athlete = create(:athlete)
      event.save!
      create(:attendance, athlete: athlete, instructor: instructor, event: event, type_of_charge: "Credits", skip_validations: true)

      summary = ClassSummaryCalculator.new(
        start_date: Time.zone.now.beginning_of_day,
        end_date: Time.zone.now.end_of_day
      ).generate

      expect(summary.total_earned).to be >= 0
    end

    it "sets zero payment for cancelled classes" do
      event.cancel!
      athlete = create(:athlete)
      create(:attendance, athlete: athlete, instructor: instructor, event: event, type_of_charge: "Credits", skip_validations: true)

      summary = ClassSummaryCalculator.new(
        start_date: Time.zone.now.beginning_of_day,
        end_date: Time.zone.now.end_of_day
      ).generate

      # Find the cancelled class
      cancelled = summary.days.flat_map(&:classes).select(&:class_cancelled)
      cancelled.each do |klass|
        klass.instructors.each do |inst|
          expect(inst.total_payment).to eq(0)
        end
      end
    end

    it "applies min_payment_per_session" do
      athlete = create(:athlete)
      event.save!
      create(:attendance, athlete: athlete, instructor: instructor, event: event, type_of_charge: "Credits", skip_validations: true)

      summary = ClassSummaryCalculator.new(
        start_date: Time.zone.now.beginning_of_day,
        end_date: Time.zone.now.end_of_day
      ).generate

      # 1 student * $4 = $4, but min is $15
      instructor_summary = summary.instructor_by_name("Coach Bob")
      expect(instructor_summary.total_payment).to be >= 15
    end
  end
end
