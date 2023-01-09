# frozen_string_literal: true

require_relative "get_map_tiles/version"
require_relative "get_map_tiles/fetcher"
require_relative "get_map_tiles/strava_heatmap"

module GetMapTiles
  class Error < StandardError; end
end
