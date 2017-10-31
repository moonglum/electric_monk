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
        unless remote_correct?
          reporter.warn("#{name}: Wrong remote '#{current_remote}'")
          return
        end
      else
        clone_project
      end

      reporter.info(name)
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
  end
end
