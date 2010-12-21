module ModsHelper
  include Blacklight::SolrHelper
  Namespace = {'mods'=>'http://www.loc.gov/mods/v3'}
  def extract_mods_details(metadata)
    details = []
    metadata[:details] = []
    xml = metadata[:xml].at_css("mods")
    return metadata unless xml
    ns = Namespace
    # title, untyped
    xml.xpath("/mods:mods/mods:titleInfo",ns).each do |node|
      key = case node.attributes["type"]
      when nil
        if node.attributes["displayLabel"].nil?
          "Title:"
        else
          "Title / #{node.attributes["displayLabel"]}:"
        end
      else
        "Title / #{node.attributes["type"]}:"
      end

      details << [key, parse_mods_title(node)]
    end
    # title, typed
    # title, displaylabel
    # form and extent
    xml.xpath("/mods:mods/mods:physicalDescription",ns).each do |node|
      node.css("extent").each do |extent|
        details << ["Extent:",extent.text]
      end
      node.xpath("./mods:form[@authority!='marcform']",ns).each do |form|
          details << ["Form:",form.text]
      end
    end
    # date
    # physicalLocation
    details += add_mods_details("Repository:", xml.xpath("/mods:mods/mods:location/mods:physicalLocation[@authority!='marcorg']",ns))
    # collection title
    # type
    xml.xpath("/mods:mods/mods:typeOfResource",ns).each do |type_node|
          details << ["Type:",type_node.text]
    end
    # project
    # project url
    # notes
    notes = []
    xml.css("note").each do |note_node|
      if note_node.attributes["displayLabel"] == "Provenance"
        details << ["Provenance:", note_node.content]
      else
        notes << note_node.content
      end
    end
    details << ["Note:", notes.join(" -- ")] unless notes.empty?
    # access condition
    details += add_mods_details("Access condition:", xml.css("accessCondition"))
    # record created / changed
    details += add_mods_details("Record created:", xml.css("recordCreationDate"))
    details += add_mods_details("Record changed:", xml.css("recordChangeDate"))
    # record IDs
    xml.xpath("/mods:mods/mods:identifier",ns).each do |id_node|
      case id_node.attributes["type"]
        when "local"
          details << ["Record ID:" ,id_node.text] unless id_node == ""
        when "CLIO"
          details << ["In CLIO:" , link_to_clio({'clio_s'=>[id_node.text]},id_node.text)] unless id_node == ""
        else
          details << ["Identifier:", id_node.text]
      end
    end
    # fedora url
    # names?
    xml.css("name").each do |name_node|
      name = parse_mods_name(name_node)
      details << ["Name:", name] unless name == ""
    end


    xml.xpath("/mods:mods/mods:originInfo",ns).each do |origin_node|
      details += add_mods_details("Publisher:", origin_node.css("publisher"))
      details += add_mods_date_details("Date Created:", origin_node.css("dateCreated"))
      details += add_mods_date_details("Date Issued:", origin_node.css("dateIssued"))
      details += add_mods_date_details("Copyright Date:", origin_node.css("copyrightDate"))
      details += add_mods_details("Edition:", origin_node.css("edition"))
    end



    xml.css("location>url").each do |url_node|
      details << ["URL:", link_to(url_node.content.to_s, url_node.content, :target => "blank")]
    end
    xml.css("relatedItem").each do |related_node|
      title = if related_node.attributes["displayLabel"].value == "Collection"
        "Collection"
      elsif related_node.attributes["displayLabel"].value == "Project"
        "Project"
      else
        false
      end
      if title
        related_node.css("titleInfo").each do |title_node|
          details << [title + ":", parse_mods_title(title_node)]
        end
      end

      related_node.css("location>url").each do |url_node|
        details << [title + " URL:", link_to(url_node.content.to_s, url_node.content, :target => "blank")]
      end
    end

    metadata[:details] = details

    return metadata

  end


  def parse_mods_title(node)

    value = ""

    value += node.at_css("nonSort").content + " " if node.at_css("nonSort")
    value += node.at_css("title").content if node.at_css("title")
    value += " : " + node.at_css("subtitle").content if node.at_css("subtitle")
    value += "  " + node.at_css("partNumber").content if node.at_css("partNumber")
    value += "  " + node.at_css("partName").content if node.at_css("partName")
    value += "  " + node.at_css("partName").content if node.at_css("partName")

    return value.strip
  end

  def parse_mods_name(name_node)
    name = ""
    name_node.css("namePart").each  do |np|
      name  += ", " if np.attributes["type"] && np.attributes["type"].value == "date"
      name += np.content
    end

    name_node.css("description").each do |desc|
      name += ", " + desc.content
    end

    return name
  end

  def add_mods_details(title, nodes)
    nodes = nodes.listify unless nodes.kind_of?(Nokogiri::XML::NodeSet)
    nodes.collect { |node| [title, node.content] }
  end


  def add_mods_date_details(title, nodes)
    before_date = nil
    end_date = nil

    nodes.each do |date_node|
      date_value = format_date_if_possible(date_node.content)
      date_value += " (inferred)" if date_node.attributes["qualifier"] == "inferred"


      if date_node.attributes.has_key?("point") && date_node.attributes["point"] == "end"
        end_date = " to " + date_value
      else
        before_date = date_value
      end

    end

    if before_date || end_date
      [[title, (before_date.to_s + end_date.to_s).strip]]
    else
      []
    end
  end

  def format_date_if_possible(date, format = :long)
    begin
      Date.parse(date).to_formatted_s(format)
    rescue
      date.to_s
    end
  end
end
