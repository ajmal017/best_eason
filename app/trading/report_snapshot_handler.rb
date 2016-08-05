require 'issue'

module Trading
  
  class ReportSnapshotHandler
    
    def initialize(xml)
      @xml = xml
      @issues = issues
    end
    
    def perform
      @issues.each { |issue| issue.create_ib_fundamental(@xml, 'current') }
    end
    
    def issues
      xml_doc.xpath('//Issues//Issue').inject([]) { |issues, issue| issues << Issue.new(issue) }
    end
    
    def xml_doc
      Nokogiri::XML(@xml)
    end
    
  end
  
end