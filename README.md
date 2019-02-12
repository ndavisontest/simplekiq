# Simplekiq

Simplekiq simplifies the boilerplate that sidekiq requires, it ensures that every job is run on a different queue and queues are no longer initialized in the sidekiq.yml

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simplekiq'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simplekiq

## Usage

#### Basics

Use `include Simplekiq::Worker` instead of `Sidekiq::Worker`

```ruby
class ReallyHardWorker
  include Simplekiq::Worker
  def perform(name, count)
    # do something
  end
end
```

This will do two things:

1. Your worker will default to the `really_hard` queue or if you are running it in a rails project it will default to the `my_app-really_hard` queue where `my_app` is your app name.

2. Running `bundle exec sidekiq` will autoload the queue names by introspecting the workers (NOTE: only workers in `app/workers` will be loaded)

Do _not_ declare queues in your sidekiq configuration file, this will throw an error.

#### Datadog

Simplekiq comes with datadog configured out of the gate, including the stats that are already passed using the [sidekiq-datadog](https://github.com/bsm/sidekiq-datadog) gem simplekiq also passes a `service:my_app` tag through the sidekiq middleware.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fzf/simplekiq. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Simplekiq project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fzf/simplekiq/blob/master/CODE_OF_CONDUCT.md).
