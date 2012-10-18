(($, that) ->
  that.copy_item = (name, from, to, amount) ->
    $('#do_add_item .item_name').val(name)
    $('#do_add_item .from_account_id').val(from)
    $('#do_add_item .to_account_id').val(to)
    $('#do_add_item .amount').val(amount)
    $('#candidates').html('')

  that.observerAddItemOnlyInput = (token) ->
    $(".item_name").delayedObserver () ->
      $.ajax {
        url: '/entry_candidates',
        type: 'get',
        data: { item_name: $("#do_add_item .item_name").val(), authenticity_token: token }
        success: (data) -> $("#candidates").html(data) }, 0.5
)(jQuery, this)
