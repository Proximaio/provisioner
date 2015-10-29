require "rubygems"
require "bundler/setup"
require "sinatra"
require File.join(File.dirname(__FILE__), "environment")
require 'ipa'
require 'nokogiri-plist'
configure do
  set :views, "#{File.dirname(__FILE__)}/views"
  set :show_exceptions, :after_handler
end


ACCEPTABLE_EXTENSIONS = %w{ipa plist}

configure :production, :development do
  enable :logging
end


module IPALibs


  FULL_IPA_PATH = 'https://dist.proxima.io/download/'


  class << self
    def binary_exists?(filename)
      false unless File.exists? file_in_ipa_path(filename)
      true
    end

    #note this should not include an IPA extension
    def file_in_ipa_path(filename)
      File.join('public', 'binaries', "#{filename}.ipa")
    end

    def binary_plist(filename)
      path = file_in_ipa_path(filename)
      ipa = ipa_local(path)
      app_url = ipa_url(filename)
      plist = PlistHelper::construct_plist(ipa.identifier, ipa.version_string, app_url, ipa.name)
      plist.to_plist_xml
    end

    def ipa_local(file_path)
      IPA::IPAFile.new(file_path)

    rescue Exception => e
      nil
    end

    def ipa_url(full_ipa_name)
      "#{FULL_IPA_PATH}#{full_ipa_name}.ipa"
    end

  end


end

module PlistHelper

  class << self
    def construct_plist(identifier, version_no, url, app_title)
      dummy_plist_structure(identifier, version_no, url, app_title)
    end

    def dummy_plist_structure(identifier, version_no, url, app_title)
      asset1 = {kind: 'software-package', url: url}
      assets = [asset1]
      metadata = {'bundle-identifier' => identifier, 'bundle-version' => version_no, 'kind' => 'Software', 'title' => app_title}
      item1 = {assets: assets, metadata: metadata}
      items = [item1]
      items
    end

  end

end

helpers do
  # add your helpers here

  def parse_request(name, ext)
    potential_ext = ext.downcase
    puts name
    puts ext
    not_found unless ACCEPTABLE_EXTENSIONS.include?(potential_ext)
    #I feel like these handlers should pass everything back if necessary
    parse_ipa_plist(name) if potential_ext == 'plist'
    # load_ipa(name) if potential_ext == 'ipa'
    #look up the name in the db
    #plists should always be in a static directory
  end

  def parse_ipa_plist(name)
    IPALibs::binary_plist(name)
    #this assumes we generate a plist based on an IPA name

  end

  def load_ipa(name)
    send_file IPALibs.file_in_ipa_path name
    #lookup for the IPA in the binaries file
    #then perform send_file for it
  end
end

not_found do
  status 404
end

# root page
get "/install/*.*" do |name, ext|

  parse_request(name, ext)

end
