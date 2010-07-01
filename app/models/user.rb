require_dependency 'vendor/plugins/blacklight/app/models/user.rb'

class User < ActiveRecord::Base
  before_validation_on_create :set_personal_info_via_ldap

  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", wind_login)) || []
      entry = entry.first

      if entry
        self.email = entry[:mail].to_s
        self.last_name = entry[:sn].to_s
        self.first_name = entry[:givenname].to_s
      end
    end

    return self
  end
end
