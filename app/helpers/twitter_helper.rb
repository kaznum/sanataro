# frozen_string_literal: true

module TwitterHelper
  TWITTER_SHARE_URL = 'https://twitter.com/intent/tweet'

  def tweet_button(item)
    url = 'http://bit.ly/Imx6PT'
    accounts = item.user.all_accounts
    from = item.from_account_id
    to = item.to_account_id

    text = if item.user.income_ids.include?(from)
             "#{item.name} [#{accounts[from]}] #{number_to_currency(item.amount)}"
           elsif item.user.expense_ids.include?(to)
             "#{item.name} [#{accounts[to]}] #{number_to_currency(item.amount)}"
           else
             "#{item.name} #{number_to_currency(item.amount)}"
           end

    tags = item.tags.to_a.sort_by(&:name)
    tags << 'sanataro'
    hashtags = tags.join(',')

    uri = URI(TWITTER_SHARE_URL)
    uri.query = {
      url: url,
      text: text,
      hashtags: hashtags,
      source: 'tweetbutton',
      lang: 'ja'
    }.to_param

    link_to(uri.to_s, class: 'tweet_button', onclick: "open_twitter(this.getAttribute('href'));return false;") do
      image_tag('twitter_icon.png', alt: 'Tweet', class: 'tweet_icon')
    end
  end
end
