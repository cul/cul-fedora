# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cul-fedora}
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Stuart"]
  s.date = %q{2010-10-11}
  s.description = %q{Columbia-specific Fedora libraries}
  s.email = %q{tastyhat@jamesstuart.org}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
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
     "lib/tika/scratch/1286482364_820891",
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
  s.rdoc_options = ["--charset=UTF-8"]
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
      s.add_runtime_dependency(%q<rsolr>, [">= 0"])
      s.add_runtime_dependency(%q<rsolr-ext>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0.9.8"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<httpclient>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rsolr>, [">= 0"])
      s.add_dependency(%q<rsolr-ext>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0.9.8"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<httpclient>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rsolr>, [">= 0"])
    s.add_dependency(%q<rsolr-ext>, [">= 0"])
  end
end

