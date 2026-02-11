require 'rails_helper'

RSpec.describe "Competition Flow", type: :model do
  describe "full competition lifecycle" do
    let(:competition) do
      create(:competition,
        name: "Spring Classic",
        start_time: 2.months.from_now,
        option_costs: {
          youth: { early: { "Speed" => 25, "Freestyle" => 30 }, late: { "Speed" => 35 } },
          adult: { early: { "Speed" => 35, "Freestyle" => 40 }, late: { "Speed" => 45 } }
        },
        coupon_codes: { "HALF" => "cost * 0.5", "FIVER" => "cost - 5" }
      )
    end

    it "registers competitors, judges them, and ranks results" do
      judge1 = create(:user, :instructor)
      judge2 = create(:user, :instructor)

      # Register adult competitors
      athlete1 = create(:athlete, full_name: "Pro Parker", date_of_birth: "01/15/2000")
      athlete2 = create(:athlete, full_name: "New Parker", date_of_birth: "06/20/1998")

      c1 = create(:competitor, competition: competition, athlete: athlete1, selected_comp: "Speed", age: athlete1.age)
      c2 = create(:competitor, competition: competition, athlete: athlete2, selected_comp: "Speed", age: athlete2.age)

      # Check costs
      expect(c1.cost).to eq(35) # adult, early
      expect(c2.cost).to eq(35)

      # Approve competitors
      c1.update!(approved_at: Time.current)
      c2.update!(approved_at: Time.current)

      # Judge them
      create(:competition_judgement, competitor: c1, judge: judge1, category: "Judge 1", category_score: 9.0, overall_impression: 8.5)
      create(:competition_judgement, competitor: c1, judge: judge2, category: "Judge 2", category_score: 8.5, overall_impression: 8.0)

      create(:competition_judgement, competitor: c2, judge: judge1, category: "Judge 1", category_score: 7.0, overall_impression: 6.5)
      create(:competition_judgement, competitor: c2, judge: judge2, category: "Judge 2", category_score: 7.5, overall_impression: 7.0)

      # Check scores
      expect(c1.score).to be > c2.score

      # Check ranking
      ranked = competition.ranked_competitors(:adult)
      expect(ranked.first).to eq(c1)
      expect(ranked.last).to eq(c2)
      expect(c1.rank).to eq(1)
      expect(c2.rank).to eq(2)
    end
  end

  describe "coupon codes" do
    let(:competition) { create(:competition) }

    it "applies percentage coupon" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: "HALF", age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost * 0.5)
    end

    it "applies flat coupon" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: "TEN", age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost - 10)
    end

    it "returns full cost for invalid coupon" do
      athlete = create(:athlete, date_of_birth: "01/15/2000")
      competitor = create(:competitor, competition: competition, athlete: athlete, selected_comp: "Speed", coupon_code: "INVALID", age: 20)
      expect(competitor.discounted_cost).to eq(competitor.cost.to_f)
    end
  end

  describe "youth vs adult separation" do
    let(:competition) { create(:competition) }

    it "separates youth and adult competitors" do
      youth_athlete = create(:athlete, date_of_birth: "01/15/#{Date.current.year - 10}")
      adult_athlete = create(:athlete, date_of_birth: "01/15/2000")

      youth_comp = create(:competitor, competition: competition, athlete: youth_athlete, age: 10)
      adult_comp = create(:competitor, competition: competition, athlete: adult_athlete, age: 20)

      expect(Competitor.youth).to include(youth_comp)
      expect(Competitor.youth).not_to include(adult_comp)
      expect(Competitor.adult).to include(adult_comp)
      expect(Competitor.adult).not_to include(youth_comp)
    end
  end

  describe "competition slug routing" do
    it "finds competition by slug" do
      comp = create(:competition, name: "Parkour Championship 2024")
      expect(comp.slug).to eq("parkour-championship-2024")
      expect(Competition.from_slug("parkour-championship-2024")).to eq(comp)
    end
  end
end
