module EmailHelper

  def html(body)
    return '' unless body.present?
    body_html = body.dup
    body_html = remove_special_characters(body_html)
    body_html = allow_raw_html_tags(body_html)
    body_html = with_standard_links(body_html)
    body_html = with_text_elements(body_html)
    body_html = centralize(body_html)
    body_html = horizontal_rules(body_html)
    body_html.html_safe
  end

  def remove_special_characters(txt)
    new_html = txt
    new_html = new_html.gsub("%[", "&#91;")
    new_html = new_html.gsub("<", "&lt;")
    new_html = new_html.gsub("\r", '')
    new_html = new_html.gsub("\n", "<br>")
    new_html
  end

  def allow_raw_html_tags(txt)
    txt.gsub(/\[html\].*?\[\/html\]/) { |txt| txt[6...-7].gsub("&lt;", "<") }
  end

  def with_standard_links(txt)
    new_html = txt.gsub(/\[link(.*?)\]/) do |txt|
      url = ''
      txt.gsub(/url="(.*?)"/) { |url_txt| url = url_txt[5..url_txt.length-2] }
      "<a href=\"#{url}\">"
    end
    new_html.gsub("[/link]", "</a>")
  end

  def with_text_elements(txt)
    new_html = txt.gsub(/\[text(.*?)\]/) do |txt|
      size = '16'
      color = '#000000'
      font = ''
      txt.gsub(/size="(.*?)"/) { |size_txt| size = size_txt[6..size_txt.length-2] }
      txt.gsub(/color="(.*?)"/) { |color_txt| color = color_txt[7..color_txt.length-2] }
      txt.gsub(/font="(.*?)"/) { |font_txt| font = font_txt[6..font_txt.length-2] }
      size_str = size.blank? ? nil : "font-size: #{size}px; "
      color_str = color.blank? ? nil : "color: #{color}; "
      font_str = font.blank? ? nil : "font-family: #{font}; "
      "<span style=\"#{size_str}#{color_str}#{font_str}\">"
    end
    new_html.gsub("[/text]", "</span>")
  end

  def centralize(txt)
    txt.gsub("[center]", "<div style=\"text-align: center;\">").gsub("[/center]", "</div>")
  end

  def horizontal_rules(txt)
    txt.gsub(/-{3,}/, "<hr>")
  end

  def valid_html?(html)
    body_html = html
    unmatched_tags = []
    body_html.gsub(/<(\w+)/) do |open_tag|
      unmatched_tags << open_tag unless ["<hr", "<br", "<img"].include?(open_tag)
      open_tag
    end
    body_html.gsub(/<\/(\w+)/) do |close_tag|
      removed_tag = unmatched_tags.slice!(unmatched_tags.index(close_tag.gsub("/", '')))
      if removed_tag.nil?
        unmatched_tags << close_tag
      end
      close_tag
    end
    unmatched_tags.length == 0
  end

end
