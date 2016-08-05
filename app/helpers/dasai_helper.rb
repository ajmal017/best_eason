module DasaiHelper
  def basket_rank(rank)
    str = case rank
          when 2
            "<em class='font_size'></em>"
          when 3
            "<em class='font_size font_img'></em>"
          else
            "<em>#{rank}.</em>"
          end
    raw str
  end
end