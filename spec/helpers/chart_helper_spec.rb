require 'spec_helper'

describe ChartHelper do
  before do
    @returned = helper.toggle_legend_link("#sample")
  end

  subject { @returned }
  it { should be =~ /^<a.*class="trivial_link".*>$/ }
  it { should be =~ /^<a .*onclick="\$\(&#x27;#sample &gt; \.legend&#x27;\)\.toggle\(\);return false;".*>$/ }
end
