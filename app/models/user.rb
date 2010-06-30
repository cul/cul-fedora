class User < ActiveRecord::Base
   
  before_validation_on_create :set_personal_info_via_ldap

  def set_personal_info_via_ldap
    if wind_login
      self.active = true

      if (entry = Connectors::CunixLdap.lookup_uid(wind_login).first)
        self.email = entry[:mail].to_s
        self.last_name = entry[:sn].to_s
        self.first_name = entry[:givenname].to_s
      end
    end
    
    return to_s
  end
end
