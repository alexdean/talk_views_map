module TalkViewsMap
  class Legend
    def initialize(options={})
      @x = options[:x]
      @y = options[:y]
      @cell_width = options[:cell_width]
      @cell_height = options[:cell_height]

      @label_color = color(options[:label_color])

      @legend = options[:legend]
      @legend_color = color(options[:legend_color])

      @font = createFont("Arial",20,true);

      @colors = {}
      @cells = {}
      options[:cells].each do |k,v|
        @colors[k] = color(v[:color])
        @cells[k] = {:label=>v[:label], :color=>@colors[k]}
      end



      @default_color = color(options[:default_color] || '#555555')

      @padding = 5
    end

    def color_for_key(key)
      @colors[key] || @default_color
    end

    def draw
      fill(0,150)
      rect(@x-@padding, @y-@padding, (@cells.size*@cell_width)+@padding*2, @cell_height*2 + (@padding*2))

      current_x=@x
      textFont(@font)
      textAlign(CENTER, CENTER);

      @cells.each do |cell_key,cell_options|
        fill(color(cell_options[:color]))
        rect(current_x, @y, @cell_width, @cell_height)

        fill(@label_color)
        text(cell_options[:label].to_s, current_x, @y, @cell_width, @cell_height)

        current_x += @cell_width
      end

      fill(@legend_color)
      text(@legend, @x, @y+@cell_height, @cells.size*@cell_width, @cell_height)
    end
  end
end