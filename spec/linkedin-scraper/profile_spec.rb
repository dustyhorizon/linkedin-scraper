require 'spec_helper'
require 'linkedin-scraper'

describe Linkedin::Profile do
  context 'stubbed tests' do
    before(:all) do
      @page = Nokogiri::HTML(File.open("spec/fixtures/jgrevich.html", 'r') { |f| f.read })
      @profile = Linkedin::Profile.new(@page, "http://www.linkedin.com/in/jgrevich")
    end

    describe "::get_profile" do
      it "Create an instance of profile class" do
        expect(@profile).to be_instance_of Linkedin::Profile
      end
    end

    describe ".first_name" do
      it 'returns the first and last name of the profile' do
        expect(@profile.first_name).to eq "Justin"
      end
    end

    describe ".last_name" do
      it 'returns the last name of the profile' do
        expect(@profile.last_name).to eq "Grevich"
      end
    end

    describe ".name" do
      it 'returns the first and last name of the profile' do
        expect(@profile.name).to eq "Justin Grevich"
      end
    end

    describe ".certifications" do
      it 'returns an array of certification hashes' do
        expect(@profile.certifications.class).to eq Array
        expect(@profile.certifications.count).to eq 2
      end

      it 'returns the certification name' do
        expect(@profile.certifications.first[:name]).to eq "CISSP"
      end

      it 'returns the certification start_date' do
        expect(@profile.certifications.first[:start_date]).to eq Date.parse('December 2010')
      end
    end

    describe ".organizations" do
      it 'returns an array of organization hashes for the profile' do
        expect(@profile.organizations.class).to eq Array
        expect(@profile.organizations.first[:name]).to eq 'San Diego Ruby'
      end
    end

    describe ".languages" do
      it 'returns an array of languages hashes' do
        expect(@profile.languages.class).to eq Array
      end

      context 'with language data' do
        it 'returns an array with one language hash' do
          expect(@profile.languages.class).to eq Array
        end

        describe 'language hash' do
          it 'contains the key and value for language name' do
            expect(@profile.languages.first[:language]).to eq 'English'
          end

          it 'contains the key and value for language proficiency' do
            expect(@profile.languages.first[:proficiency]).to eq '(Native or bilingual proficiency)'
          end
        end
      end
    end

    describe ".get_company_url" do
      let(:company_url) {
        {
          :linkedin_company_url => "http://www.linkedin.com/company/university-of-california-at-san-diego?trk=ppro_cprof",
          :url => "http://ucsd.edu",
          :type => "Educational Institution",
          :company_size => "10,001+ employees",
          :website => "http://ucsd.edu",
          :industry => "Higher Education",
          :address => "9500 Gilman Drive    La Jolla,  CA  92093  United States"
        }
      }

      it "returns a hash containing the profile's company information" do
        expect(@profile.get_company_url(@page)).to eq company_url
      end

      it 'rescue NoMethodError' do
        @page.should_receive(:at).with("h4/strong/a").and_raise NoMethodError
        expect {
          @profile.get_company_url(@page)
        }.not_to raise_error
      end
    end
  end

  context 'smoke testing' do
    context 'user profiles' do
      [
        {
          url: 'http://ca.linkedin.com/in/austinhill',
          name: 'Austin Hill'
        },
        {
          url: 'http://ca.linkedin.com/in/alecsaunders',
          name: 'Alec Saunders'
        },
        {
          url: 'http://eg.linkedin.com/in/clauspedersen100668',
          name: 'Claus Pedersen'
        },
        {
          url: 'http://eg.linkedin.com/pub/enas-younis/55/a73/6b3',
          name: 'Enas younis'
        }
      ].each do |data|
        it "return connect information for user profile #{data[:name]}" do
          profile = Linkedin::Profile.get_profile(data[:url])
          expect(profile.name).to eq data[:name]
        end
      end
    end

    context 'company profiles' do
      [
        {
          url: 'http://www.linkedin.com/company/profile-search-solutions-canada',
          name: 'Profile Search Solutions Canada'
        },
        {
          url: 'http://www.linkedin.com/company/1009?goback=%2Efcs_GLHD_*2_false_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&trk=ncsrch_hits',
          name: 'IBM'
        },
        {
          url: 'http://www.linkedin.com/company/1441',
          name: 'Google'
        },
        {
          url: 'http://www.linkedin.com/company/1123',
          name: 'Bank of America'
        }
      ].each do |data|
        it "return connect information for company profile #{data[:name]}" do
          profile = Linkedin::Profile.get_profile(data[:url])
          expect(profile.name).to eq data[:name]
        end
      end
    end
  end
end
