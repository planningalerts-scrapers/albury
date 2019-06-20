require "masterview_scraper"
require 'json'

url = "https://eservice.alburycity.nsw.gov.au/ApplicationTracker/Application/AdvancedSearchResult?DateFrom=9%2f06%2f2019&DateTo=15%2f06%2f2019&DateType=1&RemoveUndeterminedApplications=False&ApplicationType=&ShowOutstandingApplications=False&ShowExhibitedApplications=False&IncludeDocuments=False"

agent = Mechanize.new

page = agent.get(url)

MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

# Now we do a post to the API endpoint for getting applications

page = agent.post(
  "https://eservice.alburycity.nsw.gov.au/ApplicationTracker/Application/GetApplications",
  "start" => 0,
  "length" => 10,
  "json" => {
    "DateFrom" => "9/06/2019",
    "DateTo" => "15/06/2019",
    "DateType" => "1",
    "RemoveUndeterminedApplications" => false,
    "ShowOutstandingApplications" => false,
    "ShowExhibitedApplications" => false,
    "IncludeDocuments" => false
  }.to_json
)

JSON.parse(page.body)["data"].each do |application|
  record = {
    "council_reference" => application[1],
    "address"           => application[4].split("<br/>")[0].strip,
    # TODO: Do this properly
    'description'       => application[4].split("<br/>")[1].gsub("<b>", "").gsub("</b>", ""),
    'info_url'          => "https://eservice.alburycity.nsw.gov.au/ApplicationTracker/Application/ApplicationDetails/" + application[0],
    "date_scraped"      => Date.today.to_s,
    "date_received"     => Date.strptime(application[3], "%d/%m/%Y").to_s
  }
  MasterviewScraper.save(record)
end
