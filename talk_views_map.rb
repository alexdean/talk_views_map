require 'ruby-processing'

class TalkViewsMapApp < Processing::App

  load_java_library "opengl"
  load_libraries :glgraphics
  load_libraries :unfolding

  include_package "processing.opengl"
  include_package "codeanticode.glgraphics"
  include_package "de.fhpotsdam.unfolding"
  include_package "de.fhpotsdam.unfolding.geo"
  include_package "de.fhpotsdam.unfolding.providers"
  include_package "de.fhpotsdam.unfolding.mapdisplay"
  include_package "de.fhpotsdam.unfolding.utils"

  require 'csv'
  require 'time'
  require 'thread'
  require 'interpolate'

  require 'lib/talk_views_map/dot'
  require 'lib/talk_views_map/legend'
  require 'lib/talk_views_map/spark_line'
  include TalkViewsMap

  def initialize(options)
    super

    require options[:talk_view_config]
    self.class.send(:include, Module.const_get(options[:talk_view_config].split('_').map {|w| w.capitalize}.join))
    @config = config
  end

  def setup
    canvas_width = 1040
    canvas_height = 768
    size(canvas_width, canvas_height, GLConstants::GLGRAPHICS);
    # favorite: 999
    @map = Map.new(self, "map", 0, 0, canvas_width, canvas_height, true, false, OpenStreetMap::CloudmadeProvider.new(MapDisplayFactory::OSM_API_KEY, 999));

    @data = Queue.new
    start_reader_thread(@config[:data_file])

    @map.zoomAndPanTo(Location.new(36.0, -98.0), 4);
    MapUtils.createDefaultEventDispatcher(self, @map);

    @background_color = color(@config[:background_color])
    @text_color = color(@config[:text_color])

    @sec_per_frame = 20
    frameRate(15);
    background(@background_color);
    noStroke();

    @font = createFont("Arial",26,true);

    @current_dot = @data.pop
    @current_time = @current_dot[0]

    @dots = []

    @spark_line = SparkLine.new(
      :x=>20,
      :y=>height-95,
      :tz=>@display_tz
    )
    @legend = @config[:legend]

    @map.draw

    # give reader a few secs to warm the queue so we don't stall
    sleep 2

    @last_frame_began = Time.now
  end

  def start_reader_thread(data_file)
    Thread.new do
      Thread.abort_on_exception = true
      #total = `wc -l #{data_file}`.strip.to_i

      i=0
      CSV.foreach(data_file) do |row|
        t = Time.parse(row[0]+' UTC')
        @data.push([t] + row[1..3])
        i+=1
        if i%10000==0
          #puts "#{(i/total.to_f*100).round}% complete\n"
        end
        queue_length = @data.size
        if queue_length > 10000
          # sleep more as the queue gets longer
          sleep queue_length*0.00001
        end
      end
    end
  end

  def draw
    @frame_begin = Time.now

    background(@background_color)

    # dequeue as long as they're before now.
    # TODO: initial slowness due to creating a lot of dots initially? how to test?
    while (@current_dot[0] <= @current_time) do
      @dots << Dot.new(
        :sketch=>self,
        :map=>@map,
        :latitude=>@current_dot[3].to_f,
        :longitude=>@current_dot[2].to_f,
        :color=>@legend.color_for_key(@current_dot[1].to_i),
        :size=>20, #[d[4].to_i*3, 20].min,
        :growth_rate=>0.8
      )
      begin
        @current_dot = @data.pop(true)
      rescue ThreadError => e
        if e.message == "queue empty"
          puts "*** empty queue ***"
          break
        else
          raise e
        end
      end
    end

    @map.draw

    # draw dots
    size = 0
    @dots = @dots.select {|d|
      size+=1
      d.draw
    }

    # draw timer. there should be fewer literal ints here. hard to adjust everything.
    fill(0, 150)
    rect(20, height-55, 355, 35)
    textFont(@font);
    fill(@text_color);
    textAlign(LEFT,BASELINE);
    text(
      @current_time.localtime.strftime('%m/%d/%Y %I:%M:%S %p %Z'),
      25,
      height-50,
      360,
      40
    )

    if frameCount() % (@sec_per_frame/8) == 0
      @spark_line.add(size, @current_time)
    end
    @spark_line.draw

    noStroke()

    @legend.draw

    # housekeeping for next time
    @frame_duration = @frame_begin-@last_frame_began
    @last_frame_began = @frame_begin
    @current_time += @sec_per_frame

    puts "running: #{@dots.size.to_s.rjust(6)}, loaded: #{@data.length.to_s.rjust(6)}, #{(1/@frame_duration.to_f).round.to_s.rjust(4)} fps"
  end

end

TalkViewsMapApp.new :title => "Talk Views Map", :talk_view_config=>"by_talk_age_config"
