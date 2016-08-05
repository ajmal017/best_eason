class CreateSmsReports < ActiveRecord::Migration
  def change
    create_table :sms_reports do |t|
      t.string :plat_form
      t.string :f_unikey
      t.string :f_org_addr
      t.string :f_dest_addr
      t.string :f_submit_time
      t.string :f_fee_terminal
      t.string :f_service_u_p_i_d
      t.string :f_report_code
      t.string :f_link_i_d
      t.string :f_ack_status

      t.timestamps null: false
    end
  end
end
