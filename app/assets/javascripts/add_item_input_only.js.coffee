exports = this
exports.copy_item = (name, from, to, amount) ->
  $('#do_add_item #item_name').val(name)
  $('#do_add_item #from').val(from)
  $('#do_add_item #to').val(to)
  $('#do_add_item #amount').val(amount)
  $('#candidates').html('')


exports.observerAddItemOnlyInput = (token) ->
  $("#item_name").delayedObserver () ->
    $.ajax {
      url: '/entry_candidates',
      type: 'get',
      data: { item_name: $("#item_name").val(), authenticity_token: token }
      success: (data) -> $("#candidates").html(data) }, 0.5
