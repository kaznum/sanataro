module TwitterHelper
  def tweet_button(item)
    tags = item.tags.to_a
    tags << "sanataro"
    out = link_to("Tweet", "https://twitter.com/share", :class => "twitter-share-button", "data-url" => "http://bit.ly/Imx6PT",
                  "data-text" => "#{h(item.name)} (#{h(number_to_currency(item.amount))})", "data-lang" => "ja",
                  "data-count" => "none", "data-hashtags" => tags.join(","))
    out
  end
end
