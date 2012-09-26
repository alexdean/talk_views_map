module TalkViewsMap
  class Dot

    def initialize(options={})
      @longitude = options[:longitude] || 0;
      @latitude = options[:latitude] || 0;
      @dot_color = options[:color] || color(255, 255, 255);
      @final_size = options[:size] || 60;
      # num of pixels to grow per draw() call.
      @growth_rate = options[:growth_rate] || 1.0;
      @current_size = 1.0;
      @map = options[:map]
      @sketch = options[:sketch]
    end

    # return: should we keep it on the stack?
    def draw
      # TODO: current/final size aren't great names.
      # actual pixel size depends on zoom level now.
      # @final_size is really tracking the # of times we'll draw the dot. its lifetime.
      if @current_size < @final_size
        @current_size += @growth_rate;
        alpha = (@final_size-@current_size)/@final_size.to_f * 255.0;
        fill(@dot_color, alpha);

        ll = @map.getScreenPositionFromLocation(Java::DeFhpotsdamUnfoldingGeo::Location.new(@latitude, @longitude))
        @x = ll[0]
        @y = ll[1]

        if on_screen?
          size = @current_size.to_i / 64.to_f * @map.getZoom
          ellipse(@x, @y, size, size)
        end
        return true
      else
        return false
      end
    end

    def on_screen?
      @x >= 0 && @y >= 0 && @x <= @sketch.width && @y <= @sketch.height
    end
  end
end