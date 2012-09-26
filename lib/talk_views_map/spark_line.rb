module TalkViewsMap
  class SparkLine
    def initialize(options)
      @x = options[:x]
      @y = options[:y]
      @tz = options[:tz]
      # @max_pixels = options[:max_pixels]
      # @max_value = options[:max_value]
      # @height = options[:height]
      # @color = options[:color]
      @color = color('#ffffff')
      @num_points = 355
      @values = []
      @times=[]
      @height = 40
      @max_value = 4000
      @font = createFont("Arial",12,true);
    end

    def add(value, time)
      if @values.size > @num_points
        @values.shift
        @times.shift
      end
      @values.push(value)
      @times.push(time)

      @max_value = value if value > @max_value
    end

    def draw
      last_x=0
      last_y=0

      noStroke()
      fill(0, 150)
      rect(@x,@y,@num_points,@height)

      stroke(@color)
      strokeWeight(2)
      fill(@color, 255)
      textAlign(RIGHT)
      textFont(@font)

      @values.each_with_index do |v,i|
        x=@x+i
        y=@y+@height-(v/@max_value.to_f*@height).round
        if i>0
          line(last_x, last_y, x, y)
          if @times[i].hour != @times[i-1].hour
            text(@times[i].localtime.strftime('%l'), x, @y+@height)
          end
        end
        last_x=x
        last_y=y
      end
    end
  end
end
