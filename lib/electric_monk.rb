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
      if exists?
        if remote_correct?
          reporter.info(name)
        else
          reporter.warn("#{name}: Wrong remote '#{current_remote}'")
        end
      else
        reporter.wait("Cloning #{name}", name) do
          clone_project
        end
      end
    end

    private

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

    def info(msg)
      puts "✓ #{msg}"
    end

    def warn(msg)
      puts "✗ #{msg}"
    end

    def wait(waiting_msg, done_msg)
      chars = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].cycle
      show_spinner = true

      spinner = Thread.new do
        while show_spinner do
          print "#{chars.next} #{waiting_msg}"
          sleep 0.1
          print "\b" * (waiting_msg.length + 2)
        end
        padding = waiting_msg.length > done_msg.length ? " " * (waiting_msg.length - done_msg.length) : ""
        info(done_msg + padding)
      end

      yield.tap {
        show_spinner = false
        spinner.join
      }
    end
  end
end
