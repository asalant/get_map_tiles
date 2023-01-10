# frozen_string_literal: true

require "dotenv"
Dotenv.load

require_relative "get_map_tiles/version"
require_relative "get_map_tiles/fetcher"

module GetMapTiles
  class Error < StandardError; end
end
