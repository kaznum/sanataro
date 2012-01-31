class ActiveRecord::RecordInvalid
  def error_messages
    message.split(",").map(&:strip)
  end
end

