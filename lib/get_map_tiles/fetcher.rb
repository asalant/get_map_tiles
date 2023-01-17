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

    def get_northwest_corner_for_tile(zoom, x, y)
      n = 2.0 ** zoom
      lon_deg = x / n * 360.0 - 180.0
      lat_rad = Math::atan(Math::sinh(Math::PI * (1 - 2 * y / n)))
      lat_deg = 180.0 * (lat_rad / Math::PI)
      {:lat => lat_deg, :lon => lon_deg}
    end

    def get_region_for_tile(zoom, x, y)
      nw = get_northwest_corner_for_tile(zoom, x, y)
      se = get_northwest_corner_for_tile(zoom, x + 1 , y + 1)
      {:n => nw[:lat], :s => se[:lat], :w => nw[:lon], :e => se[:lon]}
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
        tiles += get_tiles_for_region_at_zoom(ne_corner, sw_corner, zoom)
      end
      tiles
    end

    def get_tiles_for_region_at_zoom(ne_corner, sw_corner, zoom)
      tiles = []
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
      tiles
    end

    def download(ne_corner, sw_corner, path_template)
      tiles = get_tiles_for_region(ne_corner, sw_corner)
      tiles.each do |tile|
        fetch_tile(tile, path_template)
      end
    end

    def generate_kml(ne_corner, sw_corner, path_template)
      (@min_zoom .. @max_zoom).each do |zoom|
        zoom_kml = render_zoom_kml(ne_corner, sw_corner, zoom, path_template)
        # TODO write kml file to tiles folder or S3
      end
    end
    
    def render_zoom_kml(ne_corner, sw_corner, zoom, path_template)
      tiles = get_tiles_for_region_at_zoom(ne_corner, sw_corner, zoom)
      tiles_kml = ""
      tiles.each do |tile| 
        tiles_kml += render_tile_kml(tile, path_template)
      end

      <<-KML
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Folder>
    <name>Winter Heatmap, zoom #{zoom}</name>
    #{tiles_kml}
  </Folder>
</kml>
      KML
    end

    def render_tile_kml(tile, path_template)
      object_key  = render_template(path_template, tile)
      region = get_region_for_tile(tile[:zoom], tile[:x], tile[:y])
      <<-KML
    <GroundOverlay>
      <name>#{object_key}</name>
      <Icon>
        <href>#{ENV['S3_BASE_URL']}#{object_key}</href>
      </Icon>
      <LatLonBox>
          <north>#{region[:n]}</north>
          <south>#{region[:s]}</south>
          <east>#{region[:e]}</east>
          <west>#{region[:w]}</west>
          <rotation>0.0</rotation>
      </LatLonBox>
    </GroundOverlay>
      KML
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
