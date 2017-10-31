# ElectricMonk

Manage your git-based projects with a CLI: It assumes that you have a directory with your
repositories and will clone/update them for you and report their status.

## Installation

Install it as a gem:

    $ gem install electric_monk

## Usage

First, you need to create the configuration file in `~/.electric_monk.toml`. The configuration file
is written in the [TOML format](https://github.com/toml-lang/toml). You need to specify where your
code repositories are located and then a list of projects:

```toml
root = "~/Code"

[projects.electric_monk]
origin = "git@github.com:moonglum/electric_monk.git"
```

Then run `electric_monk` to make sure, all projects have been cloned to your root directory. If
one is missing, `electric_monk` will clone the repository for you. If the remote is different from
what you have configured, it will show a warning.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rake` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moonglum/electric_monk.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [GNU GPLv3
License](https://www.gnu.org/licenses/gpl-3.0.txt).

## Code of Conduct

Everyone interacting in the ElectricMonk project’s codebases, issue trackers, chat rooms and mailing
lists is expected to follow the [code of
conduct](https://github.com/moonglum/electric_monk/blob/master/CODE_OF_CONDUCT.md).
