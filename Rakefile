require 'pg'
require 'csv'
require 'interpolate'
require 'color'

# set this to the current basename from http://www.maxmind.com/app/geolite
# if you download GeoLiteCity_20120807.zip, this should be 'GeoLiteCity_20120807'
IP_DATABASE = "GeoLiteCity_20120904"

def db
  @@db ||= PG.connect(dbname:'talk_views_map')
  @@db
end

def root
  @@root ||= File.expand_path File.dirname(__FILE__)
  @@root
end

namespace :jars do
  def glgraphics_jar
    "#{root}/libraries/GLGraphics/library/GLGraphics.jar"
  end
  file glgraphics_jar do
    Dir.chdir("#{root}/libraries") do
      `wget -O GLGraphics-1.0.0.zip 'http://sourceforge.net/projects/glgraphics/files/glgraphics/1.0/GLGraphics-1.0.0.zip/download?use_mirror=iweb'`
      `unzip GLGraphics-1.0.0.zip`
      `mv INSTALL.txt INSTALL-GLGraphics.txt`
    end
  end
  desc "download and install glgraphics"
  task :glgraphics => glgraphics_jar

  def unfolding_jar
    "#{root}/libraries/Unfolding/library/Unfolding.jar"
  end
  file unfolding_jar do
    Dir.chdir("#{root}/libraries") do
      `wget http://unfoldingmaps.org/download/Unfolding-0.8.0.zip`
      `unzip Unfolding-0.8.0.zip`
      `mv INSTALL.txt INSTALL-Unfolding.txt`
    end
  end
  desc "download and install unfolding"
  task :unfolding => unfolding_jar

  desc "download and install required java libs"
  task :install => [:glgraphics, :unfolding]
end

task :interpolate_colors do
  # https://github.com/m104/interpolate
  # a nice weathermap-style color gradient
  points = {
    0 => Color::RGB::Cyan,
    1 => Color::RGB::Lime,
  # 2 => ? (between Lime and Yellow; Interpolate will figure it out)
    3 => Color::RGB::Yellow,
    4 => Color::RGB::Orange,
    6 => Color::RGB::Red
  }

  # we need to implement a blending function in order for Interpolate::Points to
  # work properly
  #
  # fortunately, Color::RGB includes +mix_with+, which is almost functionally
  # identical to what we need

  gradient = Interpolate::Points.new(points)
  gradient.blend_with {|color, other, balance|
    color.mix_with(other, balance * 100.0)
  }

  # what are the colors of the gradient from 1 to 8
  # in increments of 0.2?
  (0).step(6) do |value|
    color = gradient.at(value)
    puts "#{value.to_i} => '#{color.html}',"
  end
end

namespace :output do
  task :by_talk_age do
    db.exec("DROP TABLE IF EXISTS by_talk_age")
    sql = <<-EOF
      CREATE TABLE by_talk_age (
        happened_at timestamp without time zone,
        talk_age_years int
      )
    EOF
    db.exec(sql)
    db.exec("SELECT AddGeometryColumn('public','by_talk_age','location',4326,'POINT',2)")
    sql = <<-EOF
      INSERT INTO by_talk_age (happened_at, talk_age_years, location)
      SELECT
        e.happened_at,
        extract('year' from age(happened_at,publish_date)::interval),
        i.location
      FROM events e
        INNER JOIN ip_ranges i ON e.ip_address BETWEEN i.start_ip AND i.end_ip
        LEFT JOIN talks t ON e.talk_id = t.id
    EOF
    db.exec(sql)

    sql = <<-EOF
      COPY (SELECT happened_at, talk_age_years, ST_X(location), ST_Y(location) FROM by_talk_age ORDER BY happened_at)
      TO '#{root}/generated_data/by_talk_age.csv'
      CSV
    EOF
    db.exec(sql)
  end

  task :by_device_type do
    db.exec("DROP TABLE IF EXISTS by_device_type")
    sql = <<-EOF
      CREATE TABLE by_device_type (
        happened_at timestamp without time zone,
        device_type_id int
      )
    EOF
    db.exec(sql)
    db.exec("SELECT AddGeometryColumn('public','by_device_type','location',4326,'POINT',2)")
    sql = <<-EOF
      INSERT INTO by_device_type (happened_at, device_type_id, location)
      SELECT
        e.happened_at,
        e.device_type_id,
        i.location
      FROM events e
        INNER JOIN ip_ranges i ON e.ip_address BETWEEN i.start_ip AND i.end_ip
    EOF
    db.exec(sql)

    sql = <<-EOF
      COPY (SELECT happened_at, device_type_id, ST_X(location), ST_Y(location) FROM by_device_type ORDER BY happened_at)
      TO '#{root}/generated_data/by_device_type.csv'
      CSV
    EOF
    db.exec(sql)
  end
end

namespace :base_data do
  task :load => ['talks:load', 'events:load', 'ip_ranges:load']

  namespace :talks do
    task :load => [:schema, :data, :indexes]

    def raw_talks_file
      # should be a csv file with each row containing a talk id and a publication date
      "#{root}/raw_data/talks.csv"
    end
    file raw_talks_file do
      raise "Can't find #{raw_talks_file}."
    end

    task :schema do
      db.exec("DROP TABLE IF EXISTS talks")
      sql = <<-EOF
        CREATE TABLE talks (
          id int primary key,
          publish_date timestamp without time zone
        )
      EOF
      db.exec(sql)
    end

    task :data => raw_talks_file do
      db.exec("TRUNCATE TABLE talks")
      db.exec("COPY talks FROM '#{raw_talks_file}' CSV HEADER")
    end

    task :indexes do

    end
  end

  namespace :events do
    task :load => [:schema, :data, :indexes]

    def raw_events_file
      # should be a csv file with each row containing:
      # datetime, ip address (as dotted-quad string), talk id, device type
      "#{root}/raw_data/query_result.csv"
    end
    file raw_events_file do
      raise "Can't find #{raw_events_file}."
    end

    task :schema do
      db.exec("DROP TABLE IF EXISTS events")
      sql = <<-EOF
        CREATE TABLE events (
          id serial,
          happened_at timestamp without time zone,
          ip_address inet,
          talk_id int,
          device_type_id int
        )
      EOF
      db.exec(sql)
    end

    task :data => raw_events_file do
      db.exec("TRUNCATE TABLE events")
      sql = <<-EOF
        COPY events (happened_at, ip_address, talk_id, device_type_id)
        FROM '#{raw_events_file}'
        CSV HEADER
      EOF
      db.exec(sql)
    end

    task :indexes do
      db.exec("CREATE INDEX idx_events_ip_address ON events (ip_address)")
      db.exec("CREATE INDEX idx_events_happened_at ON events (happened_at)")
      db.exec("CREATE INDEX idx_events_talk_id ON events (talk_id)")
      db.exec("CREATE INDEX idx_events_device_type_id ON events (device_type_id)")
    end
  end

  namespace :ip_ranges do
    task :load => [:schema, :data, :indexes]

    task :indexes do
      db.exec("CREATE INDEX idx_ip_ranges_start_end_ip ON ip_ranges (start_ip, end_ip)")

      # http://postgis.refractions.net/documentation/manual-2.0/using_postgis_dbmanagement.html#id590750
      db.exec("CREATE INDEX idx_ip_ranges_location ON ip_ranges USING GIST(location)")
      db.exec("VACUUM ANALYZE")
    end

    # this zip file

    def ip_data_zip_file_name
      "#{root}/raw_data/#{IP_DATABASE}.zip"
    end
    file ip_data_zip_file_name do
      raise "Can't find #{ip_data_zip_file_name}. Download from http://www.maxmind.com/app/geolite."
    end
    def unzip_data_file
      puts "unzipping" if verbose == true
      `unzip -d #{root}/generated_data #{ip_data_zip_file_name}`
      `mv #{root}/generated_data/#{IP_DATABASE}/* #{root}/generated_data`
      `rmdir #{root}/generated_data/#{IP_DATABASE}`
    end

    # contains these csv files
    file "#{root}/generated_data/GeoLiteCity-Blocks.csv" => ip_data_zip_file_name do
      unzip_data_file
    end
    file "#{root}/generated_data/GeoLiteCity-Location.csv" => ip_data_zip_file_name do
      unzip_data_file
    end

    # raw data files need to have copyright & header lines stripped before we can use pg's COPY.
    def ip_blocks_file_name
      "#{root}/generated_data/blocks.csv"
    end
    file ip_blocks_file_name => "#{root}/generated_data/GeoLiteCity-Blocks.csv" do
      puts "building #{ip_blocks_file_name}" if verbose == true
      Dir.chdir("#{root}/generated_data") do
        `tail -$((\`wc -l GeoLiteCity-Blocks.csv | awk '{print $1}'\`-2)) GeoLiteCity-Blocks.csv > blocks.csv`
      end
    end
    def ip_locations_file_name
      "#{root}/generated_data/locations.csv"
    end
    file ip_locations_file_name => "#{root}/generated_data/GeoLiteCity-Location.csv" do
      puts "building #{ip_locations_file_name}" if verbose == true
      Dir.chdir("#{root}/generated_data") do
        `tail -$((\`wc -l GeoLiteCity-Location.csv | awk '{print $1}'\`-2)) GeoLiteCity-Location.csv > locations.csv`
      end
    end

    task :data => [ip_locations_file_name, ip_blocks_file_name] do
      # load ip locations & ip blocks into tmp tables
      sql = <<-EOF
        CREATE TEMPORARY TABLE geoip_city_location (
          loc_id      INTEGER         PRIMARY KEY,
          country     CHAR(2)         NOT NULL,
          region      CHAR(2),
          city        VARCHAR(100),
          postal_code VARCHAR(10),
          latitude    DOUBLE PRECISION,
          longitude   DOUBLE PRECISION,
          metro_code  INT,
          area_code   INT
        )
      EOF
      db.exec(sql)

      sql = <<-EOF
        COPY geoip_city_location
        FROM '#{ip_locations_file_name}'
        WITH csv DELIMITER ',' NULL '' QUOTE '"' ENCODING 'ISO-8859-2'
      EOF
      db.exec(sql)

      sql = <<-EOF
        CREATE TEMPORARY TABLE geoip_city_block (
          start_ip    BIGINT      NOT NULL,
          end_ip      BIGINT      NOT NULL,
          loc_id      INTEGER     NOT NULL
        )
      EOF
      db.exec(sql)
      sql = <<-EOF
        COPY geoip_city_block
        FROM '#{ip_blocks_file_name}'
        WITH csv DELIMITER ',' NULL '' QUOTE '"' ENCODING 'ISO-8859-2'
      EOF
      db.exec(sql)

      db.exec("TRUNCATE TABLE ip_ranges")
      sql = <<-EOF
        INSERT INTO ip_ranges (start_ip, end_ip, country_code, latitude, longitude)
        SELECT
          '0.0.0.0'::inet+b.start_ip,
          '0.0.0.0'::inet+b.end_ip,
          l.country,
          l.latitude,
          l.longitude
        FROM geoip_city_block b
          INNER JOIN geoip_city_location l ON (b.loc_id = l.loc_id)
        WHERE
          latitude > 12 AND latitude < 55
          AND longitude > -135 AND longitude < -53
      EOF
      db.exec(sql)
    end

    task :schema do
      db.exec("DROP TABLE IF EXISTS ip_ranges")
      sql = <<-EOF
        CREATE TABLE ip_ranges (
          start_ip inet,
          end_ip inet,
          country_code char(2),
          latitude double precision,
          longitude double precision
        )
      EOF
      db.exec(sql)

      db.exec("SELECT AddGeometryColumn ('public','ip_ranges','location',4326,'POINT',2)")
      sql = <<-EOF
        CREATE OR REPLACE FUNCTION f_update_ip_range_location()
        RETURNS "trigger" AS
        $BODY$
          DECLARE
          BEGIN
            NEW.location = ST_SetSRID(ST_Point(NEW.longitude, NEW.latitude),4326);
            RETURN NEW;
          END
        $BODY$
        LANGUAGE 'plpgsql' VOLATILE
      EOF
      db.exec(sql)

      sql = <<-EOF
        CREATE TRIGGER t_update_ip_range_location
        BEFORE INSERT OR UPDATE ON ip_ranges
        FOR EACH ROW
        EXECUTE PROCEDURE f_update_ip_range_location()
      EOF
      db.exec(sql)
    end
  end
end
