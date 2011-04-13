require 'rubygems'
require 'thor'
require 'fileutils'
require 'powder/version'

module Powder
  class CLI < Thor
    include Thor::Actions
    default_task :link

    map '-r' => 'restart'
    map '-l' => 'list'
    map '-L' => 'link'
    map '-o' => 'open_'
    map '-v' => 'version'
    #  prevents overwriting of Kernel.open (which breaks Thor's get-method)
    map 'open' => 'open_'
    
    POWPATH = "#{`echo ~`.chomp}/.pow"

    desc "link", "Link a pow"
    def link(name=nil)
      return unless is_powable?
      name ||= current_dir
      name = pow_name(name)
      create_link "#{POWPATH}/#{name}", Dir.pwd
      say "Your application is now available at http://#{name}.#{domain}/", :green
    end

    desc "restart", "Restart current pow"
    def restart(name = nil)
      name = check_pow_dir(name)
      return if name.nil?
      app_dir = get_app_dir_for(name)
      FileUtils.mkdir_p('tmp')
      FileUtils.touch('tmp/restart.txt')
    end

    desc "list", "List current pows"
    def list
      Dir["#{POWPATH}/*"].map { |a| say "#{File.basename(a)} --> #{File.readlink(a)}" }
    end

    desc "open", "Open a pow in the browser"
    def open_(name=nil)
      name = check_pow_dir(name)
      return if name.nil?
      %x{open http://#{name}.#{domain}}
    end

    desc "remove", "Remove a pow"
    def remove(name=nil)
      name = check_pow_dir(name)
      return if name.nil?
      remove_file "#{POWPATH}/#{name}"
    end

    desc "install", "Installs pow"
    def install
      %x{curl get.pow.cx | sh}
    end

    desc "uninstall", "Uninstalls pow"
    def uninstall
      %x{curl get.pow.cx/uninstall.sh | sh}
    end
  
    desc "log", "Tails the Pow log"
    def log(name=nil)
      name = check_pow_dir(name)
      return if name.nil?
      system "tail -f ~/Library/Logs/Pow/apps/#{name}.log"
    end

    desc "version", "Shows the version"
    def version
       say "powder #{Powder::VERSION}"
    end

    private
      def pow_file_for(dir)
        Dir["#{POWPATH}/*"].find { |a| File.readlink(a) == dir }
      end
      
      def pow_file_exists?(name)
        File.exists?("#{POWPATH}/#{name}")
      end
      
      def current_dir
        Dir.pwd
      end
      
      def get_app_dir_for(name)
        File.readlink("#{POWPATH}/#{name}")
      end
    
      def pow_name(dir)
        File.basename(dir).tr('_', '-')
      end

      def check_pow_dir(name)
        if name.nil?
          pow_file = pow_file_for(current_dir)
          if pow_file.nil?
            say "The current directory is not a pow application. Please run 'powder link' first.", :red
            nil
          else
            File.basename(pow_file)
          end
        else
          if pow_file_exists?(pow_name(name))
            pow_name(name)
          else
            say "There doesn't exist a pow-application named '#{name}'.\nPlease run 'powder link #{name}' first.", :red
            nil
          end
        end
      end

      def is_powable?
        if File.exists?('config.ru') || File.exists?('public/index.html')
          true
        elsif is_rails2_app?
          say "This appears to be a Rails 2 applicaton. You need a config.ru file."
          if yes? "Do you want to autogenerate a basic config.ru for Rails 2?"
            get "https://gist.github.com/909308.txt", "#{Dir.pwd}/config.ru"
            true
          else
            say "Did not create config.ru", :red
            false
          end
        else
          say "This does not appear to be a rack app as there is no config.ru.\nPow can also host static apps if there is an index.html in public/", :red
          false
        end
      end

      def is_rails2_app?
        File.exists?('config/environment.rb') && !`grep RAILS_GEM_VERSION config/environment.rb`.empty?
      end

      def domain
        if File.exists? '~/.powconfig'
          %x{source ~/.powconfig}
          returned_domain = ENV['POW_DOMAINS'].gsub("\n", "").split(",").first
          returned_domain = ENV['POW_DOMAIN'].gsub("\n", "") if returned_domain.nil? || returned_domain.empty?
          returned_domain = 'dev' if returned_domain.nil? || returned_domain.empty?
          returned_domain
        else
          'dev'
        end
      end
  end
end
