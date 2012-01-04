exports = this
exports.htmlEscape = (s) ->
  s.replace(/&/g,'&amp;').replace(/>/g,'&gt;').replace(/</g,'&lt;').replace(/\"/g, '&quot;')
