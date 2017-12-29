require "test_helper"
require "fileutils"
require "tempfile"

class ElectricMonkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ElectricMonk::VERSION
  end

  def test_non_existent_repository
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :update_progress, nil, ["Cloning test-name"]
    reporter.expect :succeed, nil, ["test-name"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :succeed, nil, ["No untracked projects"]
    reporter.expect :report, nil, []

    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    assert_equal "# test\nA test repository (please ignore me)", read_readme
    reporter.verify
  end

  def test_existent_repository
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :succeed, nil, ["test-name"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :succeed, nil, ["No untracked projects"]
    reporter.expect :report, nil, []

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    assert_equal "# test\nA test repository (please ignore me)", read_readme
    reporter.verify
  end

  def test_existent_repository_with_wrong_remote
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :fail, nil, ["test-name: Wrong remote 'git@github.com:moonglum/false.git'"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :succeed, nil, ["No untracked projects"]
    reporter.expect :report, nil, []

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    execute "git remote set-url origin git@github.com:moonglum/false.git", chdir: "#{@dir}/test-name"
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    reporter.verify
  end

  def test_existent_repository_with_dirty_files
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :fail, nil, ["test-name: 2 dirty files and 0 unpushed commits"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :succeed, nil, ["No untracked projects"]
    reporter.expect :report, nil, []

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    execute "touch bla.txt", chdir: "#{@dir}/test-name"
    execute "echo 'HI' >> README.md", chdir: "#{@dir}/test-name"
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    reporter.verify
  end

  def test_existent_repository_with_unpushed_commits
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :fail, nil, ["test-name: 0 dirty files and 1 unpushed commits"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :succeed, nil, ["No untracked projects"]
    reporter.expect :report, nil, []

    execute "git clone git@github.com:moonglum/test.git test-name", chdir: @dir
    execute "git commit --allow-empty --no-gpg-sign -m 'An amazing commit that would be lost'", chdir: "#{@dir}/test-name"
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

    reporter.verify
  end

  def test_untracked_projects
    reporter = Minitest::Mock.new
    reporter.expect :start, nil, ["test-name"]
    reporter.expect :update_progress, nil, ["Cloning test-name"]
    reporter.expect :succeed, nil, ["test-name"]
    reporter.expect :start, nil, ["Untracked projects"]
    reporter.expect :fail, nil, ["1 untracked projects: somefolder"]
    reporter.expect :report, nil, []

    execute "mkdir somefolder", chdir: @dir
    ElectricMonk::CLI.new(config_path: @config_path, reporter: reporter).run

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
