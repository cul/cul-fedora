authorization do
  role :"staff:scv.cul.columbia.edu" do
    has_permission_on :download do
      to :fedora_content
      if_attribute :mime_type => is_not {"image/tiff"}
      # if_attribute :content_models => does_not_contain {"info:fedora/ldpd:RestrictedResource"}
    end
  end
  role :download_tiff do
    has_permission_on :download do
      to :fedora_content
      if_attribute :mime_type => is {"image/tiff"}
      # if_attribute :content_models => contains {"info:fedora/ldpd:RestrictedResource"}
    end
  end
  role :"spd23:users.scv.cul.columbia.edu" do
    includes :download_tiff
  end
  #role :"ldpd.cunix.local:columbia.edu" do
  #  includes :download_tiff
  #end
end
