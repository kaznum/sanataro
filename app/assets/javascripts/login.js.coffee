((global) ->
  $ ->
    $('#login_form').bind "ajax:before", ->
      $('#login_button').attr 'disabled', 'disabled'
    $('#login_form').bind "ajax:complete", ->
      $('#login_button').removeAttr 'disabled'
  )(this);

