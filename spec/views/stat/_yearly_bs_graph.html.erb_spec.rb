# -*- coding: utf-8 -*-
require 'spec_helper'

describe "/stat/_yearly_bs_graph.html.erb" do
  before(:each) do
    @graph_id = 100000
    @url = "http://example.com"
    render :partial => 'stat/yearly_bs_graph', :locals => { :graph_id => @graph_id, :url => @url }
  end
  subject { rendered }
  it { should have_selector "div#account_yearly_history_img_#{@graph_id}" }
  it { should have_selector "img.loading-l[src='#{@url}'][alt='yearly graph']"}
  it { should have_selector "a" }
end

