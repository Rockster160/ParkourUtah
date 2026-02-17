require 'rails_helper'

RSpec.describe Competition, type: :model do
  describe "#set_slug" do
    it "generates slug from name" do
      comp = create(:competition, name: "Summer Jam 2024")
      expect(comp.slug).to eq("summer-jam-2024")
    end

    it "allows custom slug" do
      comp = create(:competition, name: "Test", slug: "custom-slug")
      expect(comp.slug).to eq("custom-slug")
    end
  end

  describe ".from_slug" do
    it "finds competition by slug (case-insensitive)" do
      comp = create(:competition, name: "Summer Jam")
      expect(Competition.from_slug("summer-jam")).to eq(comp)
      expect(Competition.from_slug("SUMMER-JAM")).to eq(comp)
    end

    it "returns nil for non-existent slug" do
      expect(Competition.from_slug("nonexistent")).to be_nil
    end
  end

  describe "#late_registration?" do
    it "returns false before the start week" do
      comp = build(:competition, start_time: 2.months.from_now)
      expect(comp.late_registration?).to be false
    end

    it "returns true during the start week" do
      comp = build(:competition, start_time: Time.current.end_of_week)
      expect(comp.late_registration?(Time.current.end_of_week - 1.day)).to be true
    end
  end

  describe "#select_options" do
    it "returns options for the given age group and registration time" do
      comp = create(:competition)
      options = comp.select_options(:adult)
      expect(options).to be_an(Array)
      expect(options.first).to be_an(Array)
      expect(options.first.first).to include("$")
    end
  end

  describe "#cost_range" do
    it "returns formatted price range" do
      comp = create(:competition)
      range = comp.cost_range
      expect(range).to match(/\$\d+.*\$\d+/)
    end
  end

  describe "#ranked_competitors" do
    it "ranks competitors by score" do
      comp = create(:competition)
      judge = create(:user, :instructor)

      athlete1 = create(:athlete, date_of_birth: "01/15/2000")
      athlete2 = create(:athlete, date_of_birth: "01/15/2000")

      c1 = create(:competitor, :approved, competition: comp, athlete: athlete1, age: 20)
      c2 = create(:competitor, :approved, competition: comp, athlete: athlete2, age: 20)

      create(:competition_judgement, competitor: c1, judge: judge, category: "Judge 1", category_score: 9.0, overall_impression: 8.0)
      create(:competition_judgement, competitor: c2, judge: judge, category: "Judge 1", category_score: 7.0, overall_impression: 6.0)

      ranked = comp.ranked_competitors(:adult)
      expect(ranked.first).to eq(c1)
      expect(ranked.last).to eq(c2)
    end
  end

  describe "scopes" do
    it ".current returns upcoming competitions" do
      future = create(:competition, start_time: 1.month.from_now)
      past = create(:competition, start_time: 1.month.ago)
      expect(Competition.current).to include(future)
      expect(Competition.current).not_to include(past)
    end
  end
end
