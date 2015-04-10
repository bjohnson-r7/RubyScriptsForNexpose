#This script is designed to prompt the end user for a user id and then change the password for that user

#!/usr/bin/env ruby
require 'nexpose'

include Nexpose

# If these entries are set this script will not prompt the user for input

nexposehost='10.2.39.224'
nexposeport='3780'
nexposeuser='nxadmin'
nexposepassword='nxadmin'
userid = ''
userpassword = ''

if nexposehost == ''
  print "Nexpose IP: "
  nexposehost = gets.chomp
end

if nexposeport == ''
  print "Nexpose port: "
  nexposeport = gets.chomp
end

if nexposeuser == ''
  print "Nexpose Login: "
  nexposeuser = gets.chomp
end

def get_password(prompt='Nexpose Password: ')
  print prompt
  STDIN.noecho(&:gets).chomp
end

if nexposepassword == ''
  nexposepassword = get_password
end

if userid == ''
  puts ''
  print "What user id do you want to change: "
  userid=gets.chomp
end

if userpassword == ''
  puts ''
  print "New Password: "
  userpassword=gets.chomp
end

nsc = Nexpose::Connection.new(nexposehost, nexposeuser, nexposepassword, nexposeport)
nsc.login
at_exit { nsc.logout }

user = Nexpose::User.load(nsc, userid)
user.password = userpassword
user.save(nsc)
puts ''
puts 'User password has been changed'
