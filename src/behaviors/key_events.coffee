Mole.module "Behaviors", (Behaviors, App, Backbone, Marionette) ->
  Marionette.Behaviors.behaviorsLookup = Behaviors

  class Behaviors.KeyEvents extends Marionette.Behavior
    keyMap:
      18: "alt"
      8: "backspace"
      20: "caps_lock"
      188: "comma"
      91: "command"
      91: "command_left"
      93: "command_right"
      17: "control"
      46: "delete"
      40: "down"
      35: "end"
      13: "enter"
      27: "escape"
      36: "home"
      45: "insert"
      37: "left"
      93: "menu"
      107: "numpad_add"
      110: "numpad_decimal"
      111: "numpad_divide"
      108: "numpad_enter"
      106: "numpad_multiply"
      109: "numpad_subtract"
      34: "page_down"
      33: "page_up"
      190: "period"
      39: "right"
      16: "shift"
      32: "space"
      9: "tab"
      38: "up"
      91: "windows"

    defaults:
      preventDefault: []

    onShow: ->
      $(window).on 'keydown', @checkKey

    onClose: ->
      $(window).off 'keydown', @checkKey

    shouldIgnore: ->
      a = document.activeElement.tagName
      return true if a is "INPUT" or a is "TEXTAREA"

    checkKey: (event) =>
      return if @shouldIgnore()

      unless ~[16, 18, 91, 93, 17].indexOf event.which
        modifier = []
        modifier.push "ctrl"  if event.ctrlKey
        modifier.push "cmd"   if event.metaKey
        modifier.push "shift" if event.shiftKey
        modifier.push "alt"   if event.altKey

        key = @keyMap[event.which] || String.fromCharCode(event.which).toLowerCase()

        keyString = modifier
          .concat key
          .filter (e) -> e != null
          .join "+"

        if modifier.length or @keyMap[event.which]
          toInvoke = @options[keyString]
          toInvoke?.call @view, event

        if ~@options.preventDefault.indexOf(event.keyCode)
          event.preventDefault()
          return false