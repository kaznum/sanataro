module TwitterHelper
  TWITTER_SHARE_URL = "http://twitter.com/intent/tweet"
  def tweet_button(item)
    escaped_url = URI.escape("http://bit.ly/Imx6PT")
    accounts = item.user.all_accounts
    from = item.from_account_id
    to = item.to_account_id

    if item.user.income_ids.include?(from)
      escaped_text = URI.escape("#{item.name} [#{accounts[from]}] #{number_to_currency(item.amount)}")
    elsif item.user.expense_ids.include?(to)
      escaped_text = URI.escape("#{item.name} [#{accounts[to]}] #{number_to_currency(item.amount)}")
    else
      escaped_text = URI.escape("#{item.name} #{number_to_currency(item.amount)}")
    end

    tags = item.tags.to_a.sort { |a, b| a.name <=> b.name }
    tags << "sanataro"
    escaped_hashtags = URI.escape(tags.join(","))

    link_to(url_for("#{TWITTER_SHARE_URL}?url=#{escaped_url}&text=#{escaped_text}&hashtags=#{escaped_hashtags}&source=tweetbutton&lang=ja"), class: "tweet_button", onclick: "open_twitter(this.getAttribute('href'));return false;") { image_tag("twitter_icon.png", alt: "Tweet", class: "tweet_icon") }
  end
end
