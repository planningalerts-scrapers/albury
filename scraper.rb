require 'scraperwiki'
require 'rss/2.0'
require 'date'
require 'open-uri'

base_url = "https://eservice.alburycity.nsw.gov.au/portal/Pages/XC.Track/SearchApplication.aspx?"
url = "#{base_url}o=rss&d=last14days"

feed = RSS::Parser.parse(open(url).read, false)

feed.channel.items.each do |item|
  # Seeing a record without an address (which is obviously useless). So, skipping
  t = item.description.split(/[\.-]/)
  if t.count >= 2
    council_reference = item.title.split(' ')[0]
    record = {
      'council_reference' => council_reference,
      'description'       => t[1..-1].join('-').strip,
      # Have to make this a string to get the date library to parse it
      'date_received'     => Date.parse(item.pubDate.to_s),
      'address'           => t[0].strip,
      'info_url'          => "#{base_url}id=#{council_reference}",
      # Comment URL is actually an email address but I think it's best
      # they go to the detail page
      'comment_url'       => "#{base_url}id=#{council_reference}",
      'date_scraped'      => Date.today
    }

    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
       puts "Skipping already saved record " + record['council_reference']
    end
  end
end

