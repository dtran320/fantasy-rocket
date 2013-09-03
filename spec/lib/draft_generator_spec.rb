require 'spec_helper'

describe DraftGenerator do
  let(:league) do
    members = []
    league = FactoryGirl.create(:league)
    # commissioner + 9 others
    9.times do
      league.members << FactoryGirl.create(:user)
    end
    league
  end

  subject { described_class.new(league) }

  describe "#generate_picks!" do
    it "creates the right number of DraftPicks" do
      expect { subject.generate_picks! }.to change { DraftPick.count }.by(30)
    end

    it "assigns each member the same number of picks" do
      subject.generate_picks!
      league.members.each do |member|
        member.draft_picks.size.should == 3
      end
    end

    it "does not contain duplicate pick numbers" do
      subject.generate_picks!
      pick_numbers = league.draft_picks.map(&:order)
      pick_numbers.should == pick_numbers.uniq
      pick_numbers.should == (0..29).to_a
    end
  end
end

describe "DraftGenerator::DRAFT_POSITIONS_BY_LEAGUE_SIZE" do
  DraftGenerator::DRAFT_POSITIONS_BY_LEAGUE_SIZE.each do |size, positions|
    describe "leagues of size #{size}" do
      let(:picks_per_member) do
        positions.inject({}) do |ppm, member|
          ppm[member] ||= 0
          ppm[member] += 1
          ppm
        end
      end

      let(:aggregate_draft_positions) do
        adp = Array.new(size) { 0 }
        positions.each_with_index do |member, i|
          adp[member] += i
        end
        adp
      end

      it "maximizes picks_per_member" do
        picks_per_member.values.min.should == Team::TOTAL_NUMBER / size
      end

      it "distributes same number of picks to members" do
        picks_per_member.values.min.should == picks_per_member.values.max
      end

      it "distributes picks fairly to members (aggregate draft positions do not diverge by more than 1)" do
        aggregate_draft_positions.max.should <=aggregate_draft_positions.min + 1
      end
    end
  end
end
