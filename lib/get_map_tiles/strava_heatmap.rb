
# frozen_string_literal: true

module GetMapTiles
  class StravaHeatmap
    def initialize
      template = "https://heatmap-external-a.strava.com/tiles-auth/%{activity}/hot/%{z}/%{x}/%{y}.png?%{auth_params}"
      @fetcher = new Fetcher()
    end
  end
end