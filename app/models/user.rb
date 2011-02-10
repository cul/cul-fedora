require_dependency 'vendor/plugins/blacklight/app/models/user.rb'

class User < ActiveRecord::Base
  before_validation_on_create :set_personal_info_via_ldap

  named_scope :admins, :conditions => {:admin => true}

  acts_as_authentic do |c|
    c.validate_password_field = false
  end

  def to_s
    if first_name
      first_name.to_s + ' ' + last_name.to_s
    else
      login
    end
  end

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

  def self.set_staff!(unis = [])
    unis.each do |uni|
      if (u = User.find_by_login(uni))
        u.update_attributes(:email => uni + "@columbia.edu", :cul_staff => true)
      else
        User.create!(:login => uni, :wind_login => uni, :email => uni + "@columbia.edu", :cul_staff => true, :password => ActiveSupport::SecureRandom.base64(8)) 
      end
    end
  end
end
