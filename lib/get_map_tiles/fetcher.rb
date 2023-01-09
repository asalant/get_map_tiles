# frozen_string_literal: true

module GetMapTiles
  class Fetcher
    def initialize(url_template=nil, vars = {})
      @url_template = url_template
      @vars = vars
    end

    def get_tile_number(lat_deg, lng_deg, zoom)
      lat_rad = lat_deg/180 * Math::PI
      n = 2.0 ** zoom
      x = ((lng_deg + 180.0) / 360.0 * n).to_i
      y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n).to_i
      
      {:x => x, :y => y, :z => zoom}
    end

    def format_tile_url(vars)
      template_vars = {}.merge(@vars, vars)
      sprintf(@url_template, template_vars)
    end

  end

end
