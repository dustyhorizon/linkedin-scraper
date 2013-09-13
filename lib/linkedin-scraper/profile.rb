# -*- coding: utf-8 -*-
module Linkedin
  class Profile

    USER_AGENTS = ["Windows IE 6", "Windows IE 7", "Windows Mozilla", "Mac Safari", "Mac FireFox", "Mac Mozilla", "Linux Mozilla", "Linux Firefox", "Linux Konqueror"]

    DIG_DEEP = true

    attr_accessor :awards, :country, :coursework, :companies, :current_companies, :education, :first_name, :groups, :industry, :last_name, :linkedin_url, :location, :page, :past_companies, :picture, :recommended_visitors, :skills, :title, :websites, :organizations, :summary, :certifications, :languages, :num_connections, :num_recommendations, :volunteer, :interests, :honors, :projects, :publications

    def initialize(page,url)
      @first_name           = get_first_name(page)
      @last_name            = get_last_name(page)
      @title                = get_title(page)
      @location             = get_location(page)
      @country              = get_country(page)
      @industry             = get_industry(page)
      @picture              = get_picture(page)
      @summary              = get_summary(page)
      @companies            = get_all_companies(page)
      @current_companies    = get_current_companies(page)
      @past_companies       = get_past_companies(page)
      @recommended_visitors = get_recommended_visitors(page)
      @education            = get_education(page)
      @awards               = get_awards(page)
      @linkedin_url         = url
      @websites             = get_websites(page)
      @groups               = get_groups(page)
      @certifications       = get_certifications(page)
      @coursework           = get_coursework(page)
      @organizations        = get_organizations(page)
      @skills               = get_skills(page)
      @languages            = get_languages(page)
      @interests            = get_interests(page)
      @num_connections      = get_num_connections(page)
      @num_recommendations  = get_num_recommendations(page)
      @volunteer            = get_volunteer(page)
      @honors               = get_honors(page)
      @projects             = get_projects(page)
      @publications         = get_publications(page)
      @page                 = page
    end
    #returns:nil if it gives a 404 request

    def name
      name = ''
      name += "#{self.first_name} " if self.first_name
      name += self.last_name if self.last_name
      name
    end

    def self.get_profile(url)
      begin
        @agent = Mechanize.new
        @agent.user_agent_alias = USER_AGENTS.sample
        @agent.max_history = 0
        page = @agent.get(url)
        return Linkedin::Profile.new(page, url)
      rescue => e
        puts e
      end
    end

    def self.by_username(name)
      self.get_profile("http://www.linkedin.com/in/" + name)
    end

    def get_skills(page)
      page.search('.competency.show-bean').map{|skill|skill.text.strip if skill.text} rescue nil
    end

    def get_company_url(node)
      result={}
      if node.at("h4/strong/a")
        link = node.at("h4/strong/a")["href"]
        @agent = Mechanize.new
        @agent.user_agent_alias = USER_AGENTS.sample
        @agent.max_history = 0
        page = @agent.get("http://www.linkedin.com"+link)
        result[:linkedin_company_url] = "http://www.linkedin.com"+link
        result[:url] = page.at(".basic-info/div/dl/dd/a").text if page.at(".basic-info/div/dl/dd/a")
        node_2 = page.at(".basic-info").at(".content.inner-mod") if page.at(".basic-info") && page.at(".basic-info").at(".content.inner-mod")
        if node_2
          node_2.search("dd").zip(node_2.search("dt")).each do |value,title|
            result[title.text.gsub(" ","_").downcase.to_sym] = value.text.strip
          end
        end
        result[:address] = page.at(".vcard.hq").at(".adr").text.gsub("\n"," ").strip if page.at(".vcard.hq")
      end
      result
    end

    private

    def get_first_name page
      return page.at(".given-name").text.strip if page.search(".given-name").first
    end

    def get_last_name page
      return page.at(".family-name").text.strip if page.search(".family-name").first
    end

    def get_title page
      return page.at(".headline-title").text.gsub(/\s+/, " ").strip if page.search(".headline-title").first
    end

    def get_location page
      return page.at(".locality").text.split(",").first.strip if page.search(".locality").first
    end

    def get_country page
      return page.at(".locality").text.split(",").last.strip if page.search(".locality").first
    end

    def get_industry page
      return page.at(".industry").text.gsub(/\s+/, " ").strip if page.search(".industry").first
    end

    def get_summary(page)
      page.at(".description.summary").text.gsub(/\s+/, " ").strip if page.search(".description.summary").first
    end


    def get_picture page
      return page.at("#profile-picture/img.photo").attributes['src'].value.strip if page.search("#profile-picture/img.photo").first
    end

    # Example page with awards:
    # http://www.linkedin.com/in/kevinliang91

    def get_awards page
      awards = []
      query = 'ul.honorawards, li.honoraward'  
      
      if page.search(query).first
        page.search(query).each do |award|
          title = award.at('h3').content.gsub(/\s+|\n/, " ").strip
          date_select = award.at('.specifics li').content.gsub(/\s+|\n/, " ").strip
          issuer = award.at('div').content.gsub(/\s+|\n/, " ").strip
          description = award.at('.summary').content.gsub(/\s+|\n/, " ").strip       
      	end
      	awards << { date_select:date_select, description:description, issuer:issuer, title:title }
      end
  	end


    def get_all_companies(page)
      companies = []

      if page.search('.position.experience.vevent.vcard.summary-current').first
        page.search('.position.experience.vevent.vcard.summary-current').each do |company|
          start_date = Date.parse(company.at('.dtstart').content)
          duration = company.at('.period').content.slice(/\(.*\)/).slice(1..-2) if company.at('.period')
          location = company.at('.location').content.strip if company.at('.location')
          title = company.at('h3').text.gsub(/\s+|\n/, ' ').strip if company.at('h3')
          company_name = company.at('h4').text.gsub(/\s+|\n/, ' ').strip if company.at('h4')
          description = company.at('.description.current-position').text.gsub(/\s+|\n/, ' ').strip if company.at('.description.current-position')
          company = { :company_name=>company_name,
                      :current=>true,
                      :description=>description, 
                      :duration=>duration,
                      :end_date=>nil,
                      :location=>location,
                      :start_date=>start_date,
                      :title=>title
                    }
          companies << company
        end
      end

      if page.search('.position.experience.vevent.vcard.summary-past').first
        page.search('.position.experience.vevent.vcard.summary-past').each do |company|
          start_date = Date.parse(company.at('.dtstart').content)
          end_date = Date.parse(company.at('.dtend').content)
          duration = company.at('.period').content.slice(/\(.*\)/).slice(1..-2) if company.at('.period')
          location = company.at('.location').content.strip if company.at('.location')
          title = company.at('h3').text.gsub(/\s+|\n/, ' ').strip if company.at('h3')
          company_name = company.at('h4').text.gsub(/\s+|\n/, ' ').strip if company.at('h4')
          description = company.at('.description.past-position').text.gsub(/\s+|\n/, ' ').strip if company.at('.description.past-position')
          company = { :company_name=>company_name,
                      :current=>false,
                      :description=>description, 
                      :duration=>duration,
                      :end_date=>end_date,
                      :location=>location,
                      :start_date=>start_date,
                      :title=>title
                    }
          companies << company
        end
        return companies
      end

      return companies unless companies.empty?
    end
    


    def get_past_companies page
      past_cs=[]
      if page.search(".position.experience.vevent.vcard.summary-past").first
        page.search(".position.experience.vevent.vcard.summary-past").each do |past_company|
          result = get_company_url past_company if DIG_DEEP
          url = result[:url] if DIG_DEEP
          title = past_company.at("h3").text.gsub(/\s+|\n/, " ").strip if past_company.at("h3")
          company = past_company.at("h4").text.gsub(/\s+|\n/, " ").strip if past_company.at("h4")
          description = past_company.at(".description.past-position").text.gsub(/\s+|\n/, " ").strip if past_company.at(".description.past-position")
          start_date = past_company.at('abbr.dtstart').get_attribute('title') if past_company.at('abbr.dtstart')
          end_date = past_company.at('abbr.dtend').get_attribute('title') if past_company.at('abbr.dtend')
          location = past_company.at('.location').text if past_company.at('.location')
          p_company = {:past_company=>company,:past_title=> title,:past_company_website=>url,:description=>description, :start_date=>start_date, :end_date=>end_date, :location=>location}
          p_company = p_company.merge(result) if DIG_DEEP
          past_cs << p_company
        end
        return past_cs
      end
    end

    def get_current_companies page
      current_cs = []
      if page.search(".position.experience.vevent.vcard.summary-current").first
        page.search(".position.experience.vevent.vcard.summary-current").each do |current_company|
          result = get_company_url current_company if DIG_DEEP
          url = result[:url] if DIG_DEEP
          title = current_company.at("h3").text.gsub(/\s+|\n/, " ").strip if current_company.at("h3")
          company = current_company.at("h4").text.gsub(/\s+|\n/, " ").strip if current_company.at("h4")
          description = current_company.at(".description.current-position").text.gsub(/\s+|\n/, " ").strip if current_company.at(".description.current-position")
          start_date = current_company.at('abbr.dtstart').get_attribute('title') if current_company.at('abbr.dtstart')
          location = current_company.at('.location').text if current_company.at('.location')
          current_company = {:current_company=>company, :current_title=> title, :current_company_url=>url, :description=>description, :start_date=>start_date, :location=>location}
          current_cs << current_company.merge(result) if DIG_DEEP
        end
        return current_cs
      end
    end

    def get_education(page)
      education=[]
      if page.search(".position.education.vevent.vcard").first
        page.search(".position.education.vevent.vcard").each do |item|
          school   = item.at("h3").text.gsub(/\s+|\n/, " ").strip if item.at("h3")
          degree = item.at('.degree').text.gsub(/\s+|\n/, ' ').strip if item.at('.degree')
          major  = item.at('.major').text.gsub(/\s+|\n/, ' ').strip if item.at('.major')
          start_date = item.at(".dtstart").get_attribute('title') if item.at(".dtstart")
          end_date = item.at(".dtend").get_attribute('title') if item.at('.dtend')
          gpa = item.at(".desc:not([name='activities'])").text.gsub(/\s+|\n/, " ").strip if item.at(".desc:not([name='activities'])")
          description = item.search(".desc:not([name='activities'])")[1].text.gsub(/\s+|\n/, " ").strip if item.search(".desc:not([name='activities'])") && item.search(".desc:not([name='activities'])")[1]
          activities = item.at(".desc[name='activities']").text.gsub(/\s+|\n/, " ").strip if item.at(".desc[name='activities']")
          edu = {school: school, degree: degree, major: major, start_date: start_date, end_date: end_date, gpa: gpa, description: description, activities: activities}
          education << edu
        end
        return education
      end
    end

    def get_websites(page)
      websites=[]
      if page.search(".website").first
        page.search(".website").each do |site|
          url = site.at("a")["href"]
          url = "http://www.linkedin.com"+url
          url = CGI.parse(URI.parse(url).query)["url"]
          websites << url
        end
        return websites.flatten!
      end
    end

    def get_groups(page)
      groups = []
      if page.search(".group-data").first
        page.search(".group-data").each do |item|
          name = item.text.gsub(/\s+|\n/, " ").strip
          link = "http://www.linkedin.com"+item.at("a")["href"]
          groups << {:name=>name,:link=>link}
        end
        return groups
      end
    end

    def get_languages(page)
      languages = []
      # if the profile contains org data
      if page.search('ul.languages li.language').first

        # loop over each element with org data
        page.search('ul.languages li.language').each do |item|
          # find the h3 element within the above section and get the text with excess white space stripped
          language = item.at('h3').text if item.at('h3')
          proficiency = item.at('span.proficiency').text.gsub(/\s+|\n/, " ").strip if item.at('span.proficiency')
          languages << { language:language, proficiency:proficiency }
        end

        return languages
      end # page.search('ul.organizations li.organization').first
    end

    def get_certifications(page)
      certifications = []

      # search string to use with Nokogiri
      query = 'ul.certifications li.certification'
      months = 'January|February|March|April|May|June|July|August|September|November|December'
      regex = /(#{months}) (\d{4})/

      # if the profile contains cert data
      if page.search(query).first

        # loop over each element with cert data
        page.search(query).each do |item|
          name = item.at('h3').text.strip if item.at('h3')
          authority = item.at('.fn.org').text.strip if item.at('.fn.org')
          license = item.at('.license-number').text.strip if item.at('.license-number')
          start_date = item.at('.dtstart').text.strip if item.at('.dtstart')
          end_date = item.at('.dtend').text.strip if item.at('.dtend')
          certifications << { name:name, authority:authority, license:license, start_date:start_date, end_date:end_date }
        end
        return certifications
      end
    end

    def get_coursework(page)
      coursework = []
      query = 'ul li.competency'
      
      if page.search(query).first
        page.search(query).each do |course|
          grade = nil #Course do not have grades on linkedin
          number = course.at(query).content.slice(/(\d+)/)
          name = course.at(query).text.gsub(/\s+|\n/, " ").split( "(#{number})")[0].strip
          coursework << { grade:grade, name:name, number:number }
        end
      end
    end

    def get_organizations(page)
      organizations = []
      # if the profile contains org data
      if page.search('ul.organizations li.organization').first

        # loop over each element with org data
        page.search('ul.organizations li.organization').each do |item|
          # find the h3 element within the above section and get the text with excess white space stripped
          name = item.search('h3').text.gsub(/\s+|\n/, " ").strip
          position = nil # add this later
          occupation = nil # add this latetr too, this relates to the experience/work
          start_date = Date.parse(item.search('ul.specifics li').text.gsub(/\s+|\n/, " ").strip.split(' to ').first)
          if item.search('ul.specifics li').text.gsub(/\s+|\n/, " ").strip.split(' to ').last == 'Present'
            end_date = nil
          else
            Date.parse(item.search('ul.specifics li').text.gsub(/\s+|\n/, " ").strip.split(' to ').last)
          end

          organizations << { name: name, start_date: start_date, end_date: end_date }
        end

        return organizations
      end # page.search('ul.organizations li.organization').first
    end

    def get_num_connections(page)
      page.at(".overview-connections strong").text.gsub(/\s+/, " ").strip.to_i if page.search(".overview-connections strong").first
    end

    def get_num_recommendations(page)
      #recommendations are the only one in the overview not differentiated by class, so trying to say no to any classes
      page.at("#overview dd:not([class*='a']) strong").text.gsub(/\s+/, " ").strip.to_i if page.search("#overview dd:not([class*='a']) strong").first
    end

    def get_interests(page)
      page.at('#interests').text.gsub(/\s+/, " ").strip if page.search('#interests').first
    end

    def get_honors(page)
      honors = []
      if page.search("#profile-additional dd.honors").first
        page.at('#profile-additional dd.honors').text.strip.each_line{|honor| honors << honor.gsub(/\n/, "").strip}
      end
      honors
    end

    def get_volunteer(page)
      volunteer_experiences = []
      # if the profile contains org data
      if page.search('ul.volunteering li.experiences').first

        # loop over each element with org data
        page.search('ul.volunteering li.experiences').each do |item|
          # find the h3 element within the above section and get the text with excess white space stripped
          title = item.at('.title').text.strip
          organization = item.at('h5 span').text.strip
          cause = item.at('ul.specifics li').text.strip
          summary = item.at('.summary').text.gsub(/\s+|\n/, " ").strip
          start_date = item.search('.period abbr').first.get_attribute('title') if item.search('.period abbr').first
          end_date = item.search('.period abbr').last.get_attribute('title') if item.search('.period abbr').last && item.search('.period abbr').size > 1
          volunteer_experiences << { title: title, organization: organization, cause: cause, summary: summary, start_date: start_date, end_date: end_date }
        end

        return volunteer_experiences
      end # page.search('ul.organizations li.organization').first
    end

    def get_projects(page)
      projects = []
      # if the profile contains org data
      if page.search('ul.projects li.project').first

        # loop over each element with org data
        page.search('ul.projects li.project').each do |item|
          # find the h3 element within the above section and get the text with excess white space stripped
          title = item.at('h3').text.strip
          url = item.at('.url').get_attribute('href') if item.at('.url')
          duration = item.at('ul.specifics li').text.gsub(/\s+|\n/, ' ').strip
          attribution = []
          item.at('.attribution').search('a').each do |contributor|
            attribution << {name: contributor.text, url: contributor.get_attribute('href')}
          end
          summary = item.at("div:not([class*='i'])").text.gsub(/\s+|\n/, ' ').strip
          projects << { title: title, url: url, duration: duration, attribution: attribution, summary: summary}
        end

        return projects
      end # page.search('ul.organizations li.organization').first
    end

    def get_publications(page)
      publications=[]
      if page.search("ul.publications li.publication").first
        page.search("ul.publications li.publication").each do |item|
          title   = item.at("h3").text.gsub(/\s+|\n/, " ").strip if item.at("h3")
          url  = item.at("a.url").get_attribute('href') if item.at("a.url")
          source = item.at("ul.specifics li:not([class*='a'])").text if item.at("ul.specifics li:not([class*='a'])")
          date = item.at(".dtstart").text.gsub(/\s+|\n/, " ").strip if item.at(".dtstart")
          attribution = []
          item.at('.attribution').search('a').each do |author|
            attribution << {name: author.text, url: author.get_attribute('href')}
          end

          item.at('.attribution').to_s.split(',').each do |string_section|
            if !string_section.include?("<a")
              attribution << {name: string_section.gsub(/\s+|\n|<\/div>/, ' ').strip}
            end
          end
          summary = item.at('.summary').text.gsub(/\s+|\n/, ' ').strip if item.at('.summary')
          publications << {title: title, url: url, source: source, date: date, attribution: attribution, summary: summary}
        end
        return publications
      end
    end

    def get_recommended_visitors(page)
      recommended_vs=[]
      if page.search(".browsemap").first
        page.at(".browsemap").at("ul").search("li").each do |visitor|
          v = {}
          v[:link]    = visitor.at('a')["href"]
          v[:name]    = visitor.at('strong/a').text
          v[:title]   = visitor.at('.headline').text.gsub("..."," ").split(" at ").first
          v[:company] = visitor.at('.headline').text.gsub("..."," ").split(" at ")[1]
          recommended_vs << v
        end
        return recommended_vs
      end
    end
  end
end
