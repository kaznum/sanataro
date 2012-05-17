require 'spec_helper'

describe ChartHelper do
  before do
    @returned = helper.toggle_legend_link("#sample")
  end

  subject { @returned }
  it { should match /^<a.*class="trivial_link".*>$/ }
  it { should match /^<a .*onclick="\$\('#sample &gt; \.legend'\)\.toggle\(\); return false;".*>$/ }
end
