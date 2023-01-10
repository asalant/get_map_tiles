![Build status](https://github.com/asalant/get_map_tiles/actions/workflows/main.yml/badge.svg)

# GetMapTiles

Fetch a collection of map tiles from a TMS Map Source.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'get_map_tiles'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install get_map_tiles

## Usage

Copy `.env.example` to `.env` in your local project. Configure with your values.

`bin/fetch_heatmap` fetches heatmap tiles for a region you specify with lat,lon and copies them to S3 with file and directory names that let allow that S3 bucket to serve tiles as a TMS source.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/asalant/get_map_tiles.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
