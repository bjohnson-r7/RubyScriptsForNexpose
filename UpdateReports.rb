=begin
This script is designed to prompt the end user for a report template name, find any reports that use that template,
and update the reports to use the sql query that they define in the script (while preserving the other report
configuration settings).
=end


#!/usr/bin/env ruby
require 'nexpose'
require 'optparse'
require 'io/console'
require 'csv'

include Nexpose

# If these entries are set this script will not prompt the user for input
host=''
port=''
user=''
password=''
template_name=''
old_report_id = Array[]
old_report_type = Array[]


query="
  SELECT da.ip_address, da.host_name, da.mac_address, dos.description AS operating_system 
  FROM dim_asset da 
     JOIN dim_operating_system dos USING (operating_system_id) 
  WHERE da.asset_id IN ( 
     SELECT DISTINCT asset_id 
     FROM dim_asset_operating_system 
     WHERE certainty < 1 
  ) 
  ORDER BY da.ip_address"


if host == ''
  print "Nexpose IP: "
  host = gets.chomp
end

if port == ''
  print "Nexpose port: "
  port = gets.chomp
end

if user == ''
  print "User: "
  user = gets.chomp
end

def get_password(prompt='Password: ')
  print prompt
  STDIN.noecho(&:gets).chomp
end

if password == ''
  password = get_password
end

if template_name == ''
  puts ''
  print "Template Name: "
  template_name=gets.chomp
end

nsc = Nexpose::Connection.new(host, user, password, port)
nsc.login
at_exit { nsc.logout }

template = nsc.report_templates.find { |t| t.name == template_name }  
temp_id = template.id  
temp_reports = nsc.reports.select { |r| r.template_id == temp_id }  
temp_reports.each do |r|  
  report_config = Nexpose::ReportConfig.load(nsc, r.config_id)
  temp_filters = []
  report_config.filters.each do |o|
    old_report_type.push(o.type)
    old_report_id.push(o.id)
    hash = { old_report_type => old_report_id } 
    temp_filters << hash
  end
  report_config.filters = [] 
  report_config.add_filter('version', '1.4.0')
  report_config.add_filter('query', query)
  temp_filters.each do |hash|	
    hash.each do|x, y|
      x.zip(y).each do | site_name, site_id |
        report_config.add_filter(site_name, site_id.to_i) if site_name =~ /scan|site|tag|group|asset|device/
      end
	end
  end	
  report_config.format = 'sql'  
  report_config.save(nsc, generate_now = false)
end
