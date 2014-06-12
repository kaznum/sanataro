require 'spec_helper'

describe ChartHelper, :type => :helper do
  before do
    @returned = helper.toggle_legend_link("#sample")
  end

  subject { @returned }
  it { is_expected.to match(/^<a.*class="trivial_link".*>$/) }
  it { is_expected.to match(/^<a .*onclick="\$\(&#39;#sample &gt; \.legend&#39;\)\.toggle\(\);return false;".*>$/) }
end
