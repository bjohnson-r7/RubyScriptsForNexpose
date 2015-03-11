#!/usr/bin/env ruby  
require 'nexpose'   
  
include Nexpose  
nsc = Nexpose::Connection.new('host', 'username', 'password')  
nsc.login  
  
group_id = nsc.asset_groups.find { |group| group.name == 'Windows' }.id  
group = AssetGroup.load(nsc, group_id)  
group.rescan_assets(nsc) 
