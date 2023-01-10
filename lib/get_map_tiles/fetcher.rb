# frozen_string_literal: true

require "fileutils"
require "aws-sdk-s3"
require "down"

module GetMapTiles
  class Fetcher
    attr_accessor :url_template, :min_zoom, :max_zoom, :default_vars

    def initialize(url_template=nil, vars = {})
      @url_template = url_template
      @min_zoom = 6
      @max_zoom = 15
      @default_vars = vars
      @s3_client = Aws::S3::Client.new # Configured from ENV
      @s3_bucket = ENV['AWS_S3_BUCKET']
    end

    def get_tile_number(lat_deg, lng_deg, zoom)
      lat_rad = lat_deg/180 * Math::PI
      n = 2.0 ** zoom
      x = ((lng_deg + 180.0) / 360.0 * n).to_i
      y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n).to_i
      
      {:x => x, :y => y, :z => zoom}
    end

    def format_tile_url(vars)
      render_template(@url_template, vars)
    end

    def render_template(str, vars)
      template_vars = {}.merge(@default_vars, vars)
      sprintf(str, template_vars)
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

    def download(ne_corner, sw_corner, path_template)
      tiles = get_tiles_for_region(ne_corner, sw_corner)
      tiles.each do |tile|
        fetch_tile(tile, path_template)
      end
    end

    def fetch_tile(tile, path_template)
      object_key  = render_template(path_template, tile)
      print "#{object_key} downloading.. "
      tempfile = Down.download(tile[:url], max_size: 1 * 1024 * 1024) # 1 MB
      print "uploading.. "
      upload_to_s3(tile, tempfile, object_key)
      print "done.\n"
    rescue => err
      print "Failed: #{err.message}\n"
    end

    def upload_to_s3(tile, tempfile, object_key)
      @s3_client.put_object(bucket: @s3_bucket,
        key: object_key,
        body: File.read(tempfile.path),
        content_type: tempfile.content_type
      )
    end

  end

end
