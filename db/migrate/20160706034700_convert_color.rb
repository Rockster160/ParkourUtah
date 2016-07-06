class ConvertColor < ActiveRecord::Migration
  def change
    change_column :events, :color, :string
    puts "Updating Event Colors"
    Event.all.each do |event|
      print event.update(color: hex_from_string(event.color)) ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
    end
    puts "\n"
  end

  def hex_from_string(color)
    rgb = case color.to_s
    when '0', 'red' then "rgb(220, 0, 0)"
    when '1', 'orange' then "rgb(220, 128, 0)"
    when '2', 'yellow' then "rgb(220, 220, 0)"
    when '3', 'yellowgreen' then "rgb(128, 220, 0)"
    when '4', 'green' then "rgb(0, 220, 0)"
    when '5', 'cyan' then "rgb(0, 220, 220)"
    when '6', 'azure' then "rgb(0, 128, 220)"
    when '7', 'blue' then "rgb(0, 0, 220)"
    when '8', 'babyblue' then "rgb(0, 160, 255)"
    when '9', 'pink' then "rgb(255, 60, 60)"
    when '10', 'lightpurple' then "rgb(162, 97, 255)"
    when '11', 'violet' then "rgb(128, 0, 220)"
    when '12', 'magenta' then "rgb(220, 0, 220)"
    when '13', 'rose' then "rgb(220, 0, 100)"
    end

    begin
      rgb.paint.to_hex
    rescue
      colors = ['red', 'orange', 'yellow', 'yellowgreen', 'green', 'cyan', 'azure', 'blue', 'babyblue', 'pink', 'lightpurple', 'violet', 'magenta', 'rose']
      hex_from_string(colors.sample)
    end
  end

end
