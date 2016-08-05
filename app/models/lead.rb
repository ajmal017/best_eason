class Lead < ActiveRecord::Base

  attr_accessor :code

  validates :email, presence: true, uniqueness: true

  has_one :invitation_code

  has_many :invitation_codes

  belongs_to :user

  belongs_to :landing

  # 发送邮件
  def send_invite_email
    result = false

    if self.email && self.invitation_code
      result = ::UserMailer.invite_seed_user(id).deliver && self.update(invited: true, send_at: Time.now)
    end

    result
  rescue Exception => e
    false
  end

  # 批量设置邀请码
  def self.multi_set_invitation_codes(lead_ids)
    self.where(id: lead_ids).each do |lead|
      InvitationCode.create(lead_id: lead.id) if lead.invitation_code.nil?
    end
  end

  # 批量发送邮件
  def self.multi_set_invite_email(lead_ids)
    self.where(id: lead_ids).each do |lead|
      lead.send_invite_email if !lead.invited
    end
  end

  # 导入excel文件
  def self.import_with(file)
    results = []
    
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)

    return results if header.any?{|column| !self.attribute_names.include?(column) }

    (2..spreadsheet.last_row).each do |i|
      row = [header, spreadsheet.row(i)].transpose.to_h
      next if row.values.drop(1).compact.blank?
      results << self.create(row.slice(*self.attribute_names))
    end

    results
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then Roo::CSV.new(file.path, file_warning: :ignore)
    when '.xls' then Roo::Excel.new(file.path, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

end
