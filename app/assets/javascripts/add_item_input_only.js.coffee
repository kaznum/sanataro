exports = this
exports.copy_item = (name, from, to, amount) ->
  $('do_add_item').item_name.value = name
  $('do_add_item').from.value = from
  $('do_add_item').to.value = to
  $('do_add_item').amount.value = amount
  Element.update('candidates', '')


exports.observerAddItemOnlyInput = (token) ->
  new Form.Element.Observer 'item_name',1, (el, v) ->
    new Ajax.Updater 'candidates','/entry_candidates', {asynchronous:true, evalScripts:true, method:'get', parameters:'item_name='+v+'&authenticity_token='+encodeURIComponent(token)}

