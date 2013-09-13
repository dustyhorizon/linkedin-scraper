require "rubygems"
require "mechanize"
require "cgi"
require "net/http"
Dir["#{File.expand_path(File.dirname(__FILE__))}/linkedin-scraper/*.rb"].each {|file| load file }



url = "http://www.linkedin.com/in/vpoola88"
@profile = Linkedin::Profile.get_profile(url)
