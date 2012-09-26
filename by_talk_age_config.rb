module ByTalkAgeConfig
  def config
    out = {}
    out[:data_file] = 'generated_data/final.csv'
    out[:background_color] = '#000000'
    out[:text_color] = '#ffffff'
    out[:legend] = TalkViewsMap::Legend.new(
      :x=>width-300,
      :y=>20,
      :cell_width=>40,
      :cell_height=>20,
      :label_color=>out[:background_color],
      :legend=>'Talk Age In Years',
      :legend_color=>out[:text_color],
      :cells => {
        6 => {:label=>6, :color=>'#ff0000'},
        5 => {:label=>5, :color=>'#ff5300'},
        4 => {:label=>4, :color=>'#ffff00'},
        3 => {:label=>3, :color=>'#00ff00'},
        2 => {:label=>2, :color=>'#80ff00'},
        1 => {:label=>1, :color=>'#ffff00'},
        0 => {:label=>0, :color=>'#00ffff'}
      },
      :default_color=> '#ff0000'
    )
    out
  end
end
