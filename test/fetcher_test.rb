# frozen_string_literal: true

require "test_helper"

class FetcherTest < Minitest::Test

  def test_it_converts_lat_lon_to_x_y_for_zoom_14
    fetcher = ::GetMapTiles::Fetcher.new
    tile_num = fetcher.get_tile_number(39.36786, -120.36380, 14) # Just east of Peter Grubb Hut
    assert_equal(2714, tile_num[:x])
    assert_equal(6240, tile_num[:y])
    assert_equal(14, tile_num[:z])
  end

  def test_it_converts_lat_lon_to_x_y_for_zoom_15
    fetcher = ::GetMapTiles::Fetcher.new
    tile_num = fetcher.get_tile_number(39.36786, -120.36380, 15) # Just east of Peter Grubb Hut
    assert_equal(5428, tile_num[:x])
    assert_equal(12480, tile_num[:y])
    assert_equal(15, tile_num[:z])
  end

  def test_converts_tile_to_northwest_corner
    fetcher = ::GetMapTiles::Fetcher.new
    nw = fetcher.get_northwest_corner_for_tile(13, 1358, 3121) # Donner Lake Run
    assert_equal({:lat=>39.334297429807236, :lon=>-120.322265625}, nw)
  end

  def test_converts_tile_to_lat_lon_region
    fetcher = ::GetMapTiles::Fetcher.new
    region = fetcher.get_region_for_tile(13, 1358, 3121) # Donner Lake Run
    assert_equal({:n=>39.334297429807236, :s=>39.30029918615029, :w=>-120.322265625, :e=>-120.2783203125}, region)
  end

  def test_it_formats_tile_url
    url_template = "http://server/%{z}/%{x}/%{y}?%{token}"
    vars = {:x => 1, :y => 2, :z => 14, :token => 'abc'}
    fetcher = ::GetMapTiles::Fetcher.new(url_template)
    assert_equal("http://server/14/1/2?abc", fetcher.format_tile_url(vars))
  end

  def test_it_formats_tile_url_with_default_vars
    url_template = "http://server/%{z}/%{x}/%{y}?%{token}"
    vars = {:x => 1, :y => 2, :z => 14}
    fetcher = ::GetMapTiles::Fetcher.new(url_template, :token => 'abc')
    assert_equal("http://server/14/1/2?abc", fetcher.format_tile_url(vars))
  end

  def test_it_gets_tiles_for_region_at_14_zoom
    ne_corner = {:lat => 39.36786, :lon => -120.36380}
    sw_corner = {:lat => 39.35104, :lon => -120.31298}
    url_template = "http://server/%{z}/%{x}/%{y}?%{token}"
    fetcher = ::GetMapTiles::Fetcher.new(url_template, :token => 'abc')
    fetcher.min_zoom = 14
    fetcher.max_zoom = 15
    tiles = fetcher.get_tiles_for_region(ne_corner, sw_corner)
    assert_equal(21, tiles.length)
  end

  def test_it_renders_kml_for_zoom
    ne_corner = {:lat => 39.36786, :lon => -120.36380}
    sw_corner = {:lat => 39.35104, :lon => -120.31298}
    zoom = 15
    url_template = "http://server/%{z}/%{x}/%{y}?%{token}"
    path_template = "%{activity}/%{zoom}/%{x}/%{y}.png"
    fetcher = ::GetMapTiles::Fetcher.new(url_template, :token => 'abc', :activity => "winter")
    fetcher.render_zoom_kml(ne_corner, sw_corner, zoom, path_template)
    # TODO some assertion on rendered KML
  end


end

