require 'rails_helper'

RSpec.describe Competitor, type: :model do
  describe "associations" do
    it { should belong_to(:athlete) }
    it { should belong_to(:competition) }
    it { should have_many(:competition_judgements) }
  end

  describe "#cost" do
    let(:competition) { create(:competition) }

    it "returns the cost for the selected competition option" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", age: 20)
      expect(competitor.cost).to eq(35) # adult, early registration
    end
  end

  describe "#discounted_cost" do
    let(:competition) { create(:competition) }

    it "returns full cost without coupon" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: nil, age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost.to_f)
    end

    it "applies coupon code discount" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: "HALF", age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost * 0.5)
    end

    it "applies flat dollar discount" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: "TEN", age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost - 10)
    end
  end

  describe "#score" do
    it "calculates total score from judgements" do
      competitor = create(:competitor, :approved)
      judge = create(:user, :instructor)
      create(:competition_judgement, competitor: competitor, judge: judge, category: "Judge 1", category_score: 8.0, overall_impression: 7.0)
      expect(competitor.score).to eq(8.0 + 7.0)
    end

    it "returns nil when no judgements exist" do
      competitor = create(:competitor, :approved)
      expect(competitor.score).to be_nil
    end

    it "calculates category-specific score" do
      competitor = create(:competitor, :approved)
      judge = create(:user, :instructor)
      create(:competition_judgement, competitor: competitor, judge: judge, category: "Judge 1", category_score: 9.5, overall_impression: 8.0)
      expect(competitor.score("Judge 1")).to eq(9.5)
    end
  end

  describe "#score_display" do
    it "returns formatted score" do
      competitor = create(:competitor, :approved)
      judge = create(:user, :instructor)
      create(:competition_judgement, competitor: competitor, judge: judge, category: "Judge 1", category_score: 8.5, overall_impression: 7.0)
      expect(competitor.score_display).not_to eq("--")
    end

    it "returns '--' when no scores" do
      competitor = create(:competitor, :approved)
      expect(competitor.score_display).to eq("--")
    end
  end

  describe "#rank" do
    it "returns position among competitors" do
      comp = create(:competition)
      judge = create(:user, :instructor)

      a1 = create(:athlete, date_of_birth: "01/15/2000")
      a2 = create(:athlete, date_of_birth: "01/15/2000")
      c1 = create(:competitor, :approved, competition: comp, athlete: a1, age: 20)
      c2 = create(:competitor, :approved, competition: comp, athlete: a2, age: 20)

      create(:competition_judgement, competitor: c1, judge: judge, category: "Judge 1", category_score: 9.0, overall_impression: 8.0)
      create(:competition_judgement, competitor: c2, judge: judge, category: "Judge 1", category_score: 7.0, overall_impression: 6.0)

      expect(c1.rank).to eq(1)
      expect(c2.rank).to eq(2)
    end
  end

  describe "scopes" do
    it ".approved returns only approved competitors" do
      approved = create(:competitor, :approved)
      unapproved = create(:competitor, approved_at: nil)
      expect(Competitor.approved).to include(approved)
      expect(Competitor.approved).not_to include(unapproved)
    end

    it ".youth returns competitors under 14" do
      youth_athlete = create(:athlete, date_of_birth: "01/15/#{Date.current.year - 10}")
      adult_athlete = create(:athlete, date_of_birth: "01/15/2000")
      youth = create(:competitor, athlete: youth_athlete)
      adult = create(:competitor, athlete: adult_athlete)
      expect(Competitor.youth).to include(youth)
      expect(Competitor.youth).not_to include(adult)
    end
  end
end
