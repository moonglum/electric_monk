require "test_helper"
require "fileutils"
require "tempfile"

class ElectricMonkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ElectricMonk::VERSION
  end

  def test_non_existent_repository
    reporter = Minitest::Mock.new
    reporter.expect :info, nil, ["test-name"]

    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    assert_equal "# test\nA test repository (please ignore me)", read_readme
    reporter.verify
  end

  def test_existent_repository
    reporter = Minitest::Mock.new
    reporter.expect :info, nil, ["test-name"]

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    assert_equal "# test\nA test repository (please ignore me)", read_readme
    reporter.verify
  end

  def test_existent_repository_with_wrong_remote
    reporter = Minitest::Mock.new
    reporter.expect :warn, nil, ["test-name: Wrong remote 'git@github.com:moonglum/false.git'"]

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    execute "git remote set-url origin git@github.com:moonglum/false.git", chdir: "#{@dir}/test-name"
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    assert_equal "# test\nA test repository (please ignore me)", read_readme
    reporter.verify
  end

  private

  def read_readme
    File.read(File.join(@dir, "test-name", "README.md")).strip
  end

  def execute(cmd, chdir:)
    Open3.capture2e(cmd, chdir: chdir).first.strip
  end

  def around
    Dir.mktmpdir("projects", File.absolute_path("tmp")) do |dir|
      Tempfile.create("electric_monk.toml", File.absolute_path("tmp")) do |config_file|
        config = <<~CONFIG_FILE
          root = "#{dir}"

          [projects.test-name]
          origin = "git@github.com:moonglum/test.git"
        CONFIG_FILE
        config_file.write(config)
        config_file.rewind

        @dir = dir
        @config_path = config_file.path
        yield
      end
    end
  end
end
