module TalkViewsMap
  class StatusBar
    def initialize(options)
      @x = options[:x]
      @y = options[:y]
      @max_pixels = options[:max_pixels]
      @max_value = options[:max_value]
      @height = options[:height]
      @color = options[:color]
    end

    def draw(size)
      fill(@color)
      rect(@x, @y, (size/@max_value.to_f*@max_pixels).to_i, @height)
    end
  end
end