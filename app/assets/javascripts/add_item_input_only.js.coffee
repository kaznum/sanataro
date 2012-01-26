exports = this
exports.copy_item = (name, from, to, amount) ->
  $('#do_add_item #item_name').val(name)
  $('#do_add_item #from').val(from)
  $('#do_add_item #to').val(to)
  $('#do_add_item #amount').val(amount)
  $('#candidates').html('')


exports.observerAddItemOnlyInput = (token) ->
  new Form.Element.Observer 'item_name',1, (el, v) ->
    new Ajax.Updater 'candidates','/entry_candidates', {asynchronous:true, evalScripts:true, method:'get', parameters:'item_name='+v+'&authenticity_token='+encodeURIComponent(token)}

