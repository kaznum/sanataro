//= require jquery
//= require jquery_ujs
//= require html_escape
//= require add_figure
//= require_self
//= require add_item_input_only

function _view_remainsLink() {
  return "<div id='remains' class='item_remains'><a onclick=\"new Ajax.Request('/main/remaining_items.json', {asynchronous:true, evalScripts:true, onComplete:cb_showRemainingItems}); return false;\" href=\"#\">>> すべて表示する</a></div>";
}

function _view_itemLine(it, all_accounts, income_ids, account_ids) {
  result = '<div id="item_' +  it.id + '" class="item">';
  if (it.is_adjustment == 1) {
    if (it.amount < 0) {
      from_account = all_accounts[it.to_account_id];
      to_account = "(調整)";
      it.amount *= (-1);
    } else {
      from_account = "(調整)";
      to_account = all_accounts[it.to_account_id];
    }
    result += "<div class=\"item_date item_adjustment\">" + it.action_date + "</div><div class=\"item_name item_adjustment\">残高調整 " + it.adjustment_amount + "円</div><div class=\"item_from item_adjustment\">" + htmlEscape(from_account) + "</div><div class=\"item_to item_adjustment\">" + htmlEscape(to_account) + "</div><div class=\"item_amount item_adjustment\">" + add_figure(it.amount)+ "円</div><div class=\"item_operation item_adjustment\"><a onclick=\"new Ajax.Request('/main/edit_item/" + it.id+ "', {asynchronous:true, evalScripts:true}); return false;\" href=\"#\">編集</a><br/><a onclick=\"if (confirm('本当に削除しますか?')) { new Ajax.Request('/main/do_delete_adjustment/" + it.id + "', {asynchronous:true, evalScripts:true}); }; return false;\" href=\"#\">削除</a></div>";

  } else if (it.parent_id != null) {

    result += "<div class=\"item_date item_move\">" + it.action_date+ "</div><div class=\"item_name item_move\">入金 (<a onclick=\"new Ajax.Request('/main/show_parent_child_item/" + it.id+ "?type=parent', {asynchronous:true, evalScripts:true}); return false;\" href=\"#\">" + it.parent_item.action_date+ " " + htmlEscape(it.parent_item.name) + "</a>)</div><div class=\"item_from item_move\">" + htmlEscape(all_accounts[it.from_account_id]) + "</div><div class=\"item_to item_move\">" + htmlEscape(all_accounts[it.to_account_id]) + "</div><div class=\"item_amount item_move\">" + add_figure(it.amount) + "円</div><div class=\"item_operation item_move\"></div>";

  } else if (it.child_id != null) {

    if (income_ids.include(it.from_account_id)) {
      item_css_class = " item_income";
    } else if (account_ids.include(it.from_account_id) && account_ids.include(it.to_account_id)) {
      item_css_class = " item_move";
    } else {
	item_css_class = "";
    }
    result += "<div class=\"item_date" + item_css_class + "\">" +  it.action_date + "</div><div class=\"item_name" + item_css_class + "\">" +  htmlEscape(it.name) + " (<a onclick=\"new Ajax.Request('/main/show_parent_child_item/" + it.id + "?type=child', {asynchronous:true, evalScripts:true}); return false;\" href=\"#\">" + it.child_item.action_date + " 入金</a>)</div><div class=\"item_from" +  item_css_class + "\">" + htmlEscape(all_accounts[it.from_account_id]) + "</div><div class=\"item_to" +  item_css_class + "\">" + htmlEscape(all_accounts[it.to_account_id]) + "</div><div class=\"item_amount" +  item_css_class + "\">" + add_figure(it.amount)+ "円</div><div class=\"item_operation" + item_css_class+ "\"><a onclick=\"new Ajax.Request('/main/edit_item/" + it.id+ "', {asynchronous:true, evalScripts:true}); return false;\" href=\"#\">編集</a><br/><a onclick=\"if (confirm('本当に削除しますか?')) { new Ajax.Request('/main/do_delete_adjustment/" + it.id + "', {asynchronous:true, evalScripts:true}); }; return false;\" href=\"#\">削除</a></div>";

  } else {

    if (income_ids.include(it.from_account_id) ) {
      item_css_class = " item_income";
    } else if (account_ids.include(it.from_account_id) && account_ids.include(it.to_account_id)) {
      item_css_class = " item_move";
    } else {
      item_css_class = "";
    }
    result += "<div class=\"item_date" +  item_css_class + "\">" +  it.action_date + "</div><div class=\"item_name" +  item_css_class + "\">" +  htmlEscape(it.name) + "</div><div class=\"item_from" +  item_css_class + "\">" +  htmlEscape(all_accounts[it.from_account_id]) + "</div><div class=\"item_to" +  item_css_class + "\">" +  htmlEscape(all_accounts[it.to_account_id]) + "</div><div class=\"item_amount" +  item_css_class + "\">" +  add_figure(it.amount) + "円</div><div class=\"item_operation" + item_css_class+ "\"><a onclick=\"new Ajax.Request('/main/edit_item/" + it.id+ "', {asynchronous:true, evalScripts:true}); return false;\" href=\"#\">編集</a><br/><a onclick=\"if (confirm('本当に削除しますか?')) { new Ajax.Request('/main/do_delete_adjustment/" + it.id + "', {asynchronous:true, evalScripts:true});}; return false;\" href=\"#\">削除</a></div>";
  }
  result += "</div><div class=\"reset\"></div>";
  return result;
}

var config;

function initialize_main_items() {
  new Ajax.Request('/main/config.json', {asynchronous:false, evalScripts:true, onComplete:cb_setConfig});
  new Ajax.Request('/main/items.json', {asynchronous:true, evalScripts:true, onComplete:cb_showItems});
}

function cb_setConfig(request) {
  config = eval("("+request.responseText+")");
}

function cb_showItems(request) {
  items = eval("("+request.responseText+")");
  items.each(function(it) {
	       new Insertion.Bottom('items', _view_itemLine(it, config['all_accounts'], config['income_ids'], config['account_ids']));
	     });
  new Insertion.Bottom('items', _view_remainsLink());
}

function cb_showRemainingItems(request) {
  new Effect.Fade("remains",{duration:0.3});
  setTimeout(function() {
	       Element.remove("remains");
	     }, 2000);
  items = eval("("+request.responseText+")");
  items.each(function(it) {
	       new Insertion.Bottom('items', _view_itemLine(it, config['all_accounts'], config['income_ids'], config['account_ids']));
	     });
}

