# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cul-fedora}
  s.version = "0.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Stuart"]
  s.date = %q{2011-06-02}
  s.description = %q{Columbia-specific Fedora libraries}
  s.email = %q{tastyhat@jamesstuart.org}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "cul-fedora.gemspec",
    "lib/cul-fedora.rb",
    "lib/cul-fedora/item.rb",
    "lib/cul-fedora/server.rb",
    "lib/cul-fedora/solr.rb",
    "lib/test",
    "lib/tika/Flexibleapptsfinal.doc",
    "lib/tika/asm-3.1.jar",
    "lib/tika/bcmail-jdk14-132.jar",
    "lib/tika/bcprov-jdk14-132.jar",
    "lib/tika/commons-codec-1.3.jar",
    "lib/tika/commons-io-1.4.jar",
    "lib/tika/commons-lang-2.1.jar",
    "lib/tika/commons-logging-1.0.4.jar",
    "lib/tika/dom4j-1.6.1.jar",
    "lib/tika/fontbox-0.1.0-dev.jar",
    "lib/tika/icu4j-3.8.jar",
    "lib/tika/log4j-1.2.14.jar",
    "lib/tika/nekohtml-1.9.9.jar",
    "lib/tika/ooxml-schemas-1.0.jar",
    "lib/tika/pdfbox-0.7.3.jar",
    "lib/tika/poi-3.5-beta5.jar",
    "lib/tika/poi-ooxml-3.5-beta5.jar",
    "lib/tika/poi-scratchpad-3.5-beta5.jar",
    "lib/tika/scratch/1286827167_3249395",
    "lib/tika/tika-0.3.jar",
    "lib/tika/xercesImpl-2.8.1.jar",
    "lib/tika/xml-apis-1.0.b2.jar",
    "lib/tika/xmlbeans-2.3.0.jar",
    "test/data/125467_get_index.xml",
    "test/data/125467_solr_doc.xml",
    "test/data/example_server_requests.yml",
    "test/helper.rb",
    "test/test_cul-fedora.rb",
    "test/test_fedora_item.rb",
    "test/test_fedora_server.rb",
    "test/test_fedora_solr.rb",
    "test_fedora_item.rb"
  ]
  s.homepage = %q{http://github.com/tastyhat/cul-fedora}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Columbia University Fedora Hooks}
  s.test_files = [
    "test/helper.rb",
    "test/test_cul-fedora.rb",
    "test/test_fedora_item.rb",
    "test/test_fedora_server.rb",
    "test/test_fedora_solr.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0.9.8"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<httpclient>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<rsolr>, [">= 0.12.1"])
      s.add_runtime_dependency(%q<rsolr-ext>, [">= 0.12.1"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0.9.8"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<httpclient>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rsolr>, [">= 0.12.1"])
      s.add_dependency(%q<rsolr-ext>, [">= 0.12.1"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0.9.8"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<httpclient>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rsolr>, [">= 0.12.1"])
    s.add_dependency(%q<rsolr-ext>, [">= 0.12.1"])
  end
end

