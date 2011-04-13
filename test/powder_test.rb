require 'test_helper'

class TestPowder < Test::Unit::TestCase
  include Construct::Helpers
  
  def setup
    @powder = Powder::CLI.new
    @powder.stubs(:domain).returns('dev')
  end
  
  def test_link_command_with_rack_app
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      appdir = construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
      end
      assert_file("#{powdir}/rackapp")
      assert_equal File.readlink("#{powdir}/rackapp"), appdir.to_s
    end
  end
  
  def test_link_command_with_rack_app_with_name
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link, ['otherapp'])
      end
      assert_file("#{powdir}/otherapp")
      assert_no_file("#{powdir}/rackapp")
    end
  end
  
  def test_link_command_with_static_app
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'staticapp' do |dir|
        dir.file 'public/index.html'
        @powder.invoke(:link)
      end
      assert_file("#{powdir}/staticapp")
    end
  end
 
  def test_link_command_with_rack_app_with_underscores
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp_with_underscores' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
      end
      assert_file("#{powdir}/rackapp-with-underscores")
    end
  end
  
  def test_link_command_with_rails2_app_download
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'railstwoapp' do |dir|
        dir.file 'config/environment.rb', 'RAILS_GEM_VERSION'
        $stdin.expects(:gets).returns('y')
        @powder.invoke(:link)
        assert_file('config.ru')
      end
      assert_file("#{powdir}/railstwoapp")
    end
  end
  
  def test_link_command_with_rails2_app_no_download
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'railstwoapp' do |dir|
        dir.file 'config/environment.rb', 'RAILS_GEM_VERSION'
        $stdin.expects(:gets).returns('n')
        @powder.invoke(:link)
        assert_no_file('config.ru')
      end
      assert_no_file("#{powdir}/railstwoapp")
    end
  end
 
  def test_link_command_with_no_app
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'noapp' do |dir|
        @powder.invoke(:link)
      end
      assert_no_file("#{powdir}/noapp")
    end
  end
  
  def test_restart_command_in_pow_dir
    within_construct do |construct|
      reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
        @powder.invoke(:restart)
        assert_file("tmp/restart.txt")
      end
    end
  end
  
  def test_restart_command_outside_of_pow_dir
    within_construct do |construct|
      reset_powpath(construct.directory('.pow'))
      construct.directory 'noapp' do |dir|
        @powder.invoke(:restart)
        assert_no_file("tmp/restart.txt")
      end
    end
  end
  
  def test_list_command
    within_construct do |construct|
      reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
      end
      out = capture_stdout { @powder.invoke(:list) }
      assert out.string =~ /rackapp/
      assert !(out.string =~ /otherapp/)
    end
  end
  
  def test_remove_command_in_pow_dir
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
        assert_file("#{powdir}/rackapp")
        @powder.invoke(:remove)
        assert_no_file("#{powdir}/rackapp")
      end
    end
  end
  
  def test_remove_command_in_pow_dir_with_custom_name
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link, ['otherapp'])
        assert_file("#{powdir}/otherapp")
        @powder.invoke(:remove)
        assert_no_file("#{powdir}/otherapp")
      end
    end
  end
  
  def test_remove_command_outside_of_pow_dir
    within_construct do |construct|
      powdir = reset_powpath(construct.directory('.pow'))
      appdir = construct.directory 'rackapp' do |dir|
        dir.file 'config.ru'
        @powder.invoke(:link)
      end
      assert_not_equal Dir.pwd, appdir.to_s
      @powder.invoke(:remove, ['rackapp'])
      assert_no_file("#{powdir}/rackapp")
    end
  end

  
  def test_version_command
    out = capture_stdout { @powder.invoke(:version) }
    assert_equal out.string, "powder #{Powder::VERSION}\n"
  end
  
end