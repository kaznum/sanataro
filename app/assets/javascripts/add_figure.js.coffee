exports = this
exports.add_figure = (str) ->
  num = new String(str).replace(/,/g, "")
  result = ""
  until result == num
    result = num
    num = num.replace(/^(-?\d+)(\d{3})/, "$1,$2")
  result

