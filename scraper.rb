#!/usr/bin/env ruby

require 'nokogiri'
require 'watir'
require 'aws-sdk-comprehend'
require 'net/http'

browser = Watir::Browser.new

def list_links(subreddit, browser)
  browser.goto("https://old.reddit.com/r/#{subreddit}/")
  #page = Net::HTTP.get(uri)
  #puts page
  doc = Nokogiri::HTML(browser.html) 
  links = []
  doc.css("a.title").each do |title|
    links.push(title.children.first.text)
  end
  return links
end

def sentiment_for_link(link, client)
  res = client.detect_sentiment({
   text: link,
   language_code: "en",
  })
  return res.sentiment  
end

interesting_pages = [
 "canada",
 "ireland",
 "unitedkingdom",
 "news"
]

ARGV.each do|a|
  interesting_pages.push(a)
end

page_links = {}

puts "-----START FINDING LINKS-----"

interesting_pages.each do |country|
  country_links = list_links(country, browser)
  page_links[country] = country_links
end

puts "-----LINKS LOADED-----"


page_links.each do |page, links|
  puts "\n\n-----#{page.upcase} LINKS-----\n\n"

  client = Aws::Comprehend::Client.new
  sentiments = []
  links.each do |link|
    s = sentiment_for_link(link, client)
    sentiments.push(s)
  end
  sentiments = sentiments.sort
  sentiments = sentiments.select { |sen| sen != "NEUTRAL" }

  if !sentiments.any?
    puts "NO STRONG SENTIMENTS"
  else 
    puts sentiments
  end
end





