require "electric_monk/version"
require "toml-rb"
require "open3"
require "singleton"

module ElectricMonk
  class CLI
    attr_reader :config

    def initialize(config_path:, reporter: Reporter.instance)
      @config = Config.new(config_path, reporter)
    end

    def run
      config.projects.each do |project|
        project.ensure_existence
      end
    end
  end

  class Config
    def initialize(path, reporter)
      @config = TomlRB.load_file(path)
      @reporter = reporter
    end

    def root
      @root ||= File.expand_path(@config.fetch("root"))
    end

    def projects
      @config.fetch("projects").map do |name, attributes|
        Project.new(
          root: root,
          name: name,
          origin: attributes.fetch("origin"),
          reporter: @reporter
        )
      end
    end
  end

  class Project
    attr_reader :root
    attr_reader :name
    attr_reader :origin
    attr_reader :reporter

    def initialize(root:, name:, origin:, reporter:)
      @root = root
      @name = name
      @origin = origin
      @reporter = reporter
    end

    def ensure_existence
      reporter.start(name)

      if exists?
        if remote_correct?
          if dirty_files?
            reporter.fail("#{name}: #{dirty_files} dirty files")
          elsif unpushed_commits?
            reporter.fail("#{name}: #{unpushed_commits} unpushed commits")
          else
            reporter.succeed(name)
          end
        else
          reporter.fail("#{name}: Wrong remote '#{current_remote}'")
        end
      else
        reporter.update_progress("Cloning #{name}")
        clone_project
        reporter.succeed(name)
      end
    end

    private

    def dirty_files?
      dirty_files > 0
    end

    def dirty_files
      execute("git status --short", chdir: path).lines.length
    end

    def unpushed_commits?
      unpushed_commits > 0
    end

    def unpushed_commits
      execute("git log --oneline --branches --not --remotes", chdir: path).lines.length
    end

    def current_remote
      execute("git remote get-url origin", chdir: path)
    end

    def clone_project
      execute("git clone #{origin} #{name}", chdir: root)
    end

    def remote_correct?
      origin == current_remote
    end

    def exists?
      File.exist?(path)
    end

    def path
      File.join(root, name)
    end

    def execute(cmd, chdir:)
      Open3.capture2e(cmd, chdir: chdir).first.strip
    end
  end

  class Reporter
    include Singleton

    def start(task_name)
      @task_name = task_name
      @final_message = nil

      @spinner = Thread.new do
        chars = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].cycle
        until @final_message do
          current_task_name = @task_name
          print "#{chars.next} #{current_task_name}"
          sleep 0.1
          print "\b \b" * (current_task_name.length + 2)
        end
        puts @final_message
      end
    end

    def update_progress(task_name)
      @task_name = task_name
    end

    def succeed(msg)
      @final_message = "✓ #{msg}"
      @spinner.join
    end

    def fail(msg)
      @final_message = "✗ #{msg}"
      @spinner.join
    end
  end
end
