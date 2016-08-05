class Sector < ActiveRecord::Base
  ABBREV_CATEGORY = {
    "sector_bm" => "基础材料",
    "sector_c" => "综合型大企业",
    "sector_cg" => "消费品",
    "sector_f" => "金融",
    "sector_h" => "医疗",
    "sector_ig" => "工业",
    "sector_s" => "服务业",
    "sector_t" => "高科技",
    "sector_u" => "公用事业",
    "sector_o" => "其他"
  }
  
  CATEGORY = {
    "Basic Materials" => "基础材料",
    "Conglomerates" => "综合型大企业",
    "Consumer Goods" => "消费品",
    "Financial" => "金融",
    "Healthcare" => "医疗",
    "Industrial Goods" => "工业",
    "Services" => "服务业",
    "Technology" => "高科技",
    "Utilities" => "公用事业",
    "Others" => "其他",
    "Cash" => "现金"
  }
  
  MAPPING = {
    "10" => "能源",
    "15" => "原材料",
    "20" => "工业",
    "25" => "非日常生活消费品",
    "30" => "日常消费品",
    "35" => "医疗保健",
    "40" => "金融",
    "45" => "信息技术",
    "55" => "公用事业"
  }

  C_MAPPING = MAPPING.merge("0" => "现金")

  COLORS = {
    "0" =>  "#cccccc",
    "10" => "#ffa500",
    "15" => "#fac611",
    "20" => "#385dae",
    "25" => "#655cd4",
    "30" => "#ff2860",
    "35" => "#0091ff",
    "40" => "#ff4546",
    "45" => "#0bbcf4",
    "55" => "#31c464",
    "-1" => "#59b726",  #其他
  }
  
  E_MAPPING = {
    "10" => "Energy",
    "15" => "Materials",
    "20" => "Industries",
    "25" => "Consumer Discretionary",
    "30" => "Consumer Staples",
    "35" => "Health Care",
    "40" => "Financials",
    "45" => "Information Technology",
    "55" => "Utilities"
  }

  FIRST_MAPPINGS = {
    "financial"  => 40,
    "healthcare" => 35,
    "industrial goods" => 20,
    "technology" => 45,
    "utilities" => 55
  }

  SECOND_MAPPINGS = {
    "Appliances"=>25,
    "Auto Manufacturers - Major"=>25,
    "Auto Parts"=>25,
    "Electronic Equipment"=>25,
    "Home Furnishings & Fixtures"=>25,
    "Housewares & Accessories"=>25,
    "Personal Products"=>25,
    "Photographic Equipment & Supplies"=>25,
    "Recreational Goods"=>25,
    "Recreational Vehicles"=>25,
    "Sporting Goods"=>25,
    "Textile - Apparel Clothing"=>25,
    "Textile - Apparel Footwear & Accessories"=>25,
    "Toys & Games"=>25,
    "Trucks & Other Vehicles"=>25,
    "Advertising Agencies"=>25,
    "Apparel Stores"=>25,
    "Auto Dealerships"=>25,
    "Auto Parts Stores"=>25,
    "Auto Parts Wholesale"=>25,
    "Broadcasting - Radio"=>25,
    "Broadcasting - TV"=>25,
    "Business Services"=>25,
    "Catalog & Mail Order Houses"=>25,
    "CATV Systems"=>25,
    "Consumer Services"=>25,
    "Department Stores"=>25,
    "Discount"=>25,
    "Education & Training Services"=>25,
    "Electronics Stores"=>25,
    "Electronics Wholesale"=>25,
    "Entertainment - Diversified"=>25,
    "Gaming Activities"=>25,
    "General Entertainment"=>25,
    "Home Furnishing Stores"=>25,
    "Home Improvement Stores"=>25,
    "Jewelry Stores"=>25,
    "Lodging"=>25,
    "Marketing Services"=>25,
    "Movie Production"=>25,
    "Music & Video Stores"=>25,
    "Personal Services"=>25,
    "Publishing - Books"=>25,
    "Publishing - Newspapers"=>25,
    "Publishing - Periodicals"=>25,
    "Rental & Leasing Services"=>25,
    "Resorts & Casinos"=>25,
    "Restaurants"=>25,
    "Specialty Eateries"=>25,
    "Specialty Retail"=>25,
    "Sporting Activities"=>25,
    "Sporting Goods Stores"=>25,
    "Toy & Hobby Stores"=>25,
    "Beverages - Brewers"=>30,
    "Beverages - Soft Drinks"=>30,
    "Beverages - Wineries & Distillers"=>30,
    "Cigarettes"=>30,
    "Cleaning Products"=>30,
    "Confectioners"=>30,
    "Dairy Products"=>30,
    "Farm Products"=>30,
    "Food - Major Diversified"=>30,
    "Meat Products"=>30,
    "Tobacco Products"=>30,
    "Food Wholesale"=>30,
    "Grocery Stores"=>30,
    "Independent Oil & Gas"=>10,
    "Major Integrated Oil & Gas"=>10,
    "Oil & Gas Drilling & Exploration"=>10,
    "Oil & Gas Equipment & Services"=>10,
    "Oil & Gas Pipelines"=>10,
    "Oil & Gas Refining & Marketing"=>10,
    "Drug Stores"=>35,
    "Drugs Wholesale"=>35,
    "Medical Equipment Wholesale"=>35,
    "Conglomerates"=>20,
    "Business Equipment"=>20,
    "Office Supplies"=>20,
    "Processed & Packaged Goods"=>20,
    "Air Delivery & Freight Services"=>20,
    "Air Services"=>20,
    "Basic Materials Wholesale"=>20,
    "Industrial Equipment Wholesale"=>20,
    "Major Airlines"=>20,
    "Management Services"=>20,
    "Railroads"=>20,
    "Regional Airlines"=>20,
    "Shipping"=>20,
    "Staffing & Outsourcing Services"=>20,
    "Technical Services"=>20,
    "Trucking"=>20,
    "Computers Wholesale"=>45,
    "Research Services"=>45,
    "Security & Protection Services"=>45,
    "Agricultural Chemicals"=>15,
    "Aluminum"=>15,
    "Chemicals - Major Diversified"=>15,
    "Copper"=>15,
    "Gold"=>15,
    "Industrial Metals & Minerals"=>15,
    "Nonmetallic Mineral Mining"=>15,
    "Silver"=>15,
    "Specialty Chemicals"=>15,
    "Steel & Iron"=>15,
    "Synthetics"=>15,
    "Packaging & Containers"=>15,
    "Paper & Paper Products"=>15,
    "Rubber & Plastics"=>15,
    "Building Materials Wholesale"=>15
  }

  def self.find_sector_code_by(sector, industry)
    FIRST_MAPPINGS[sector.downcase] || SECOND_MAPPINGS[industry] || Sector::SECOND_MAPPINGS[industry.split(',').first]
  end

  def self.find_color_by_zh(name_zh)
    COLORS[C_MAPPING.key(name_zh)]
  end

end
