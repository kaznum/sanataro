module TwitterHelper
  TWITTER_SHARE_URL = "http://twitter.com/intent/tweet"
  def tweet_button(item)
    escaped_url = URI.escape("http://bit.ly/Imx6PT")
    from = item.user.accounts.where(id: item.from_account_id).first
    to = item.user.accounts.where(id: item.to_account_id).first

    if from.is_a?(Income)
      escaped_text = URI.escape("#{item.name} [#{from.name}] #{number_to_currency(item.amount)}")
    elsif to.is_a?(Expense)
      escaped_text = URI.escape("#{item.name} [#{to.name}] #{number_to_currency(item.amount)}")
    else
      escaped_text = URI.escape("#{item.name} #{number_to_currency(item.amount)}")
    end

    tags = item.tags.to_a.sort{|a,b| a.name <=> b.name}
    tags << "sanataro"
    escaped_hashtags = URI.escape(tags.join(","))

    link_to(url_for("#{TWITTER_SHARE_URL}?url=#{escaped_url}&text=#{escaped_text}&hashtags=#{escaped_hashtags}&source=tweetbutton&lang=ja"), class: "tweet_button", onclick: "open_twitter(this.getAttribute('href'));return false;") { image_tag("twitter_icon.png", alt: "Tweet", class: "tweet_icon") }
  end
end

