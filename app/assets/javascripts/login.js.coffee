jQuery ($) ->
  $ ->
    $('#login_form').bind "ajax:before", ->
      $('#login_button').attr 'disabled', true
    $('#login_form').bind "ajax:complete", ->
      $('#login_button').attr 'disabled', false

