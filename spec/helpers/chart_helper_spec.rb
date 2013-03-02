require 'spec_helper'

describe ChartHelper do
  before do
    @returned = helper.toggle_legend_link("#sample")
  end

  subject { @returned }
  it { should be =~ /^<a.*class="trivial_link".*>$/ }
  it { should be =~ /^<a .*onclick="\$\(&#39;#sample &gt; \.legend&#39;\)\.toggle\(\);return false;".*>$/ }
end
