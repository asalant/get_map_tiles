# frozen_string_literal: true

require "down"

module GetMapTiles
  class Fetcher
    attr_accessor :url_template, :min_zoom, :max_zoom, :default_vars

    def initialize(url_template=nil, vars = {})
      @url_template = url_template
      @min_zoom = 6
      @max_zoom = 15
      @default_vars = vars
    end

    def get_tile_number(lat_deg, lng_deg, zoom)
      lat_rad = lat_deg/180 * Math::PI
      n = 2.0 ** zoom
      x = ((lng_deg + 180.0) / 360.0 * n).to_i
      y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n).to_i
      
      {:x => x, :y => y, :z => zoom}
    end

    def format_tile_url(vars)
      template_vars = {}.merge(@default_vars, vars)
      sprintf(@url_template, template_vars)
      
    end

    def get_tiles_for_region(ne_corner, sw_corner)
      tiles = []
      (@min_zoom .. @max_zoom).each do |zoom|
        ne_tile = get_tile_number(ne_corner[:lat], ne_corner[:lon], zoom)
        sw_tile = get_tile_number(sw_corner[:lat], sw_corner[:lon], zoom)

        (ne_tile[:x] .. sw_tile[:x]).each do |x|
          (ne_tile[:y] .. sw_tile[:y]).each do |y|
            tiles << {
              :url => format_tile_url(:x => x, :y => y, :z => zoom),
              :x => x,
              :y => y,
              :zoom => zoom
            }
          end
        end
      end
      tiles
    end

    def download(ne_corner, sw_corner)
      tiles = get_tiles_for_region(ne_corner, sw_corner)
      tiles.each do |tile|
        dir  = sprintf "./tiles/%{zoom}/%{x}", tile
        FileUtils.mkdir_p dir
        file = sprintf "#{dir}/%{y}.png", tile
        puts "Downloading #{file}"
        Down.download(tile[:url], destination: file, max_size: 1 * 1024 * 1024) # 1 MB
      end
    end


  end

end
