module TwitterHelper
  TWITTER_SHARE_URL = "http://twitter.com/intent/tweet"
  def tweet_button(item)
    escaped_url = URI.escape("http://bit.ly/Imx6PT")
    escaped_text = URI.escape("#{item.name} (#{number_to_currency(item.amount)})")
    tags = item.tags.to_a
    tags << "sanataro"
    escaped_hashtags = URI.escape(tags.join(","))
                              
    link_to(image_tag("http://a4.twimg.com/images/favicon.ico", :alt=> "Tweet"), url_for("#{TWITTER_SHARE_URL}?url=#{escaped_url}&text=#{escaped_text}&hashtags=#{escaped_hashtags}&source=tweetbutton&lang=ja"), class: "tweet_button", onclick: "open_twitter(this.getAttribute('href'));return false;")
  end
end
