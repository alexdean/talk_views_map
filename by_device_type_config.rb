module ByDeviceTypeConfig
  def config
    out = {}
    out[:data_file] = 'generated_data/by_device_type.csv'
    out[:background_color] = '#000000'
    out[:text_color] = '#ffffff'
    out[:legend] = TalkViewsMap::Legend.new(
      :x=>width-300,
      :y=>20,
      :cell_width=>40,
      :cell_height=>20,
      :label_color=>out[:background_color],
      :legend=>'Talks By Device Type',
      :legend_color=>out[:text_color],
      :cells => {
        5 => {:label=>'tv', :color=>'#ff5300'},
        4 => {:label=>'mob', :color=>'#ff0000'},
        3 => {:label=>'tblt', :color=>'#00ff00'},
        2 => {:label=>'pc', :color=>'#80ff00'},
        1 => {:label=>'unk', :color=>'#ffff00'},
      },
      :default_color=> '#ffff00'
    )
    out
  end
end
