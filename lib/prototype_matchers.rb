#if defined?(::Rails) && ::Rails.env == 'test' || ::RAILS_ENV == 'test'
require 'rspec'
RSpec::Matchers.define :have_prototype_rjs_of do |*prms|
  match do |actual|
    expected = prms.clone
    type = expected.shift
    case type
    when :delay
      timeout = expected.shift
      matched = (actual =~ /setTimeout\(function\(\) \{(.+)\}, #{(timeout.to_f * 1000).to_i}\);/m)
    when :replace_html
      selector_id = expected.shift
      body = expected.shift
      if body.nil?
        matched = (actual =~ /Element\.update\("#{selector_id}", /)
      else
        matched = (actual =~ /Element\.update\("#{selector_id}", "#{Regexp.escape(body)}"/)
      end
    when :replace
      selector_id = expected.shift
      body = expected.shift
      if body.nil?
        matched = (actual =~ /Element\.replace\("#{selector_id}", /)
      else
        matched = (actual =~ /Element\.replace\("#{selector_id}", "#{Regexp.escape(body)}"/)
      end
    when :visual_effect
      effect = expected.shift
      selector_id = expected.shift
      options = expected.extract_options!
      if options.empty?
        matched = (actual =~ /new Effect\.#{effect.to_s.camelize}\("#{selector_id}"/)
      else
        # TODO: the order of key/value pairs may have problems
        serialized_options = options.map{ |key, value| "#{key}:#{value}" }.join(",")
        matched = (actual =~ /new Effect\.#{effect.to_s.camelize}\("#{selector_id}",\{#{serialized_options}\}\);/)
      end
    when :redirect_to
      url = expected.shift
      matched = (actual =~ /window\.location\.href = "#{Regexp.escape(url)}"/)
    else
      raise ArgumentError.new("No matcher for #{prms.join(", ")}")
    end

    matched
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have RJS of #{prms.join(", ")} but do not."
  end
  
  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have RJS of #{prms.join(", ")} but exist."
  end

  description do
    "have RJS text of prototype.js or scriptaculous helpers"
  end
end
#end
