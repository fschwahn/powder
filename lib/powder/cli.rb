require 'rubygems'
require 'thor'
require 'fileutils'
require 'net/https'
require 'powder/version'

module Powder
  class CLI < Thor
    include Thor::Actions
    default_task :link

    map '-r' => 'restart'
    map '-l' => 'list'
    map '-L' => 'link'
    map '-o' => 'open'
    map '-v' => 'version'

    POWPATH = "#{`echo ~`.chomp}/.pow"

    desc "link", "Link a pow"
    def link(name=nil)
      return unless is_powable?
      current_path = %x{pwd}.chomp
      name ||= current_dir_pow_name
      symlink_path = "#{POWPATH}/#{name}"
      FileUtils.ln_s(current_path, symlink_path) unless File.exists?(symlink_path)
      say "Your application is now available at http://#{name}.#{domain}/"
    end

    desc "restart", "Restart current pow"
    def restart
      return unless is_powable?
      FileUtils.mkdir_p('tmp')
      %x{touch tmp/restart.txt}
    end

    desc "list", "List current pows"
    def list
      Dir[POWPATH + "/*"].map { |a| say File.basename(a) }
    end

    desc "open", "Open a pow in the browser"
    def open(name=nil)
      %x{open http://#{name || current_dir_pow_name}.#{domain}}
    end

    desc "remove", "Remove a pow"
    def remove(name=nil)
      return unless is_powable?
      FileUtils.rm_f POWPATH + '/' + (name || current_dir_pow_name)
    end

    desc "install", "Installs pow"
    def install
      %x{curl get.pow.cx | sh}
    end

    desc "log", "Tails the Pow log"
    def log(name=nil)
      system "tail -f ~/Library/Logs/Pow/apps/#{name || current_dir_pow_name}.log"
    end

    desc "uninstall", "Uninstalls pow"
    def uninstall
      %x{curl get.pow.cx/uninstall.sh | sh}
    end
  
    desc "version", "Shows the version"
    def version
       say "powder #{Powder::VERSION}"
    end

    private

    def current_dir_pow_name
      File.basename(%x{pwd}.chomp).tr('_', '-')
    end

    def is_powable?
      if File.exists?('config.ru') || File.exists?('public/index.html')
        true
      elsif is_rails2_app?
        say "This appears to be a Rails 2 applicaton. You need a config.ru file."
        if yes? "Do you want to autogenerate a basic config.ru for Rails 2?"
          uri = URI.parse("https://gist.github.com/909308.txt")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          create_file "config.ru",  http.request(request).body
          return true
        else
          say "Did not create config.ru"
          return false
        end
      else
        say "This does not appear to be a rack app as there is no config.ru."
        say "Pow can also host static apps if there is an index.html in public/"
        return false
      end
    end
  
    def is_rails2_app?
      File.exists?('config/environment.rb') && !`grep RAILS_GEM_VERSION config/environment.rb`.empty?
    end

    def domain
      if File.exists? '~/.powconfig'
        returned_domain = %x{source ~/.powconfig; echo $POW_DOMAINS}.gsub("\n", "").split(",").first
        returned_domain = %x{source ~/.powconfig; echo $POW_DOMAIN}.gsub("\n", "") if returned_domain.nil? || returned_domain.empty?
        returned_domain = 'dev' if returned_domain.nil? || returned_domain.empty?
        returned_domain
      else
        'dev'
      end
    end
  end
end
