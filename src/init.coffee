
$ ->

  Mole.start nwWindow: window.nwWindow

  $weekList = $(".week-list")

  $weekList.panelSnap
    panelSelector: '.week'

  $weekList.on "mousedown", ".drag-border", (mousedownEvent) ->
    initialMouseX = mousedownEvent.screenX
    initialMouseY = mousedownEvent.screenY
    $draggedElement = $(this).parent()
    initialHeight = $draggedElement.height()

    stepHeightPx = Math.floor ($weekList.height() / 40)
    stepHeightPc = 2.5

    $weekList.on "mousemove", (mousemoveEvent) ->
      currentMouseX = mousemoveEvent.screenX
      currentMouseY = mousemoveEvent.screenY
      deltaY = (currentMouseY - initialMouseY)

      minutes = ((initialHeight + deltaY) / stepHeightPx) * 15
      remainder = minutes % 15
      minutes = minutes - remainder

      $draggedElement.trigger "previewFromDrag", minutes: minutes

    $weekList.on "mouseup", (mouseupEvent) ->
      finalMouseX = mouseupEvent.screenX
      finalMouseY = mouseupEvent.screenY

      minutes = ($draggedElement.height() / stepHeightPx) * 15
      console.log minutes

      remainder = minutes % 15
      minutes = minutes - remainder

      console.log minutes
      $draggedElement.trigger "updateFromDrag", minutes: minutes

      $weekList.off "mousemove"
      $weekList.off "mouseup"