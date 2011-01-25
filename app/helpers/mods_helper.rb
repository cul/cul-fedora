module ModsHelper
  include Blacklight::SolrHelper
  Namespace = {'mods'=>'http://www.loc.gov/mods/v3'}
  def extract_mods_details(metadata)
    details = []
    metadata[:details] = []
    if metadata[:xml].nil?
      return metadata
    end
    xml = metadata[:xml].at_css("mods")
    return metadata unless xml
    ns = Namespace
    # names
    xml.xpath("/mods:mods/mods:name",ns).each do |node|
      name = parse_mods_name(node)
      name ||= ""
      details << ["Name:", name] unless name == ""
    end
    # title, untyped
    # title, typed
    # title, displaylabel
    xml.xpath("/mods:mods/mods:titleInfo",ns).each do |node|
      details << [get_mods_title_label(node), parse_mods_title(node)]
    end
    # form
    xml.xpath("/mods:mods/mods:physicalDescription/mods:form[@authority!='marcform']",ns).each do |node|
      details << ["Form:",node.text]
    end
    # type
    xml.xpath("/mods:mods/mods:typeOfResource",ns).each do |type_node|
          details << ["Type:",type_node.text]
    end
    # extent
    xml.xpath("/mods:mods/mods:physicalDescription/mods:extent",ns).each do |node|
      details << ["Extent:",node.text]
    end
    # place
    xml.xpath("/mods:mods/mods:originInfo/mods:place/mods:placeTerm[@type='text']",ns).each do |node|
      details << ["Place:",node.text]
    end
    # publisher
    xml.xpath("/mods:mods/mods:originInfo/mods:publisher",ns).each do |node|
      details << ["Publisher:",node.text]
    end
    # date
    xml.xpath("/mods:mods/mods:originInfo",ns).each do |node|
      node.xpath("./mods:dateCreated",ns).each do |date|
        value = get_mods_date_details(date)
        if date.attributes["point"]
          details << ["Date / #{date.attr("point")}:",value]
        else
          details << ["Date:",value]
        end
      end
      node.xpath("./mods:dateIssued",ns).each do |date|
        value = get_mods_date_details(date)
        if date.attributes["point"]
          details << ["Date / #{date.attr("point")}:",value]
        else
          details << ["Date:",value]
        end
      end
    end
    # notes
    notes = []
    xml.css("note").each do |node|
      if node.attributes["displayLabel"] == "Provenance"
        details << ["Provenance:", node.content]
      else
        notes << node.content
      end
    end
    details << ["Note:", notes.join(" -- ")] unless notes.empty?
    # URL (external)
    xml.xpath("/mods:mods/mods:location/mods:url",ns).each do |node|
      details << ["URL:", link_to(node.content.to_s, node.content, :target => "blank")]
    end
    # physicalLocation
    nodes = xml.xpath("/mods:mods/mods:location/mods:physicalLocation",ns) - xml.xpath("/mods:mods/mods:location/mods:physicalLocation[@authority='marcorg']",ns)
    details += add_mods_details("Repository:", nodes)
    details += add_mods_details("Sublocation:", xml.xpath("/mods:mods/mods:location/mods:shelfLocator",ns))
    # collection, project, project url
    xml.xpath("/mods:mods/mods:relatedItem[@type='host']/mods:titleInfo",ns).each do |node|
      if node.xpath("..").first.attributes["displayLabel"]
        label = node.xpath("..").first.attr("displayLabel").sub(/./) {|s| s.upcase}
        label += ":"
        value = parse_mods_title(node)
        if node.xpath("../mods:location/mods:url",ns).first
          value = link_to(value,node.xpath("../mods:location/mods:url",ns).first.text, :target=>"blank")
        end
        details << [label, value]
      end
    end
    # access condition
    details += add_mods_details("Access condition:", xml.css("accessCondition"))
    # record created / changed
    details += add_mods_details("Record created:", xml.css("recordCreationDate"))
    details += add_mods_details("Record changed:", xml.css("recordChangeDate"))
    # record IDs
    xml.xpath("/mods:mods/mods:identifier",ns).each do |node|
      case node.attr("type")
        when "local"
          details << ["Record ID:" ,node.text] unless node == ""
        when "CLIO"
          details << ["In CLIO:" , link_to_clio({'clio_s'=>[node.text]},node.text)] unless node == ""
        else
          details << ["Identifier:", node.text]
      end
    end
    # fedora url

    metadata[:details] = details

    return metadata

  end


  def get_mods_title_label(node)
    if node.attributes["type"]:
      "Title / #{node.attributes["type"]}:"
    elsif node.attributes["displayLabel"]
      "Title / #{node.attributes["displayLabel"]}:"
    else
      "Title:"
    end
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


  def get_mods_date_details(date_node)
    date_value = format_date_if_possible(date_node.content)
    date_value += " (inferred)" if date_node.attributes["qualifier"] == "inferred"
    date_value += " (approx.)" if date_node.attributes["qualifier"] == "approximate"
    date_value += " ?" if date_node.attributes["qualifier"] == "questionable"
    date_value
  end

  def format_date_if_possible(date, format = :long)
    begin
      Date.parse(date).to_formatted_s(format)
    rescue
      date.to_s
    end
  end
end
