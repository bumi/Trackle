
$ ->

  Mole.start nwWindow: window.nwWindow

  Raygun.init('qpf4QU6c4uq/tYwvoegH8A==',
    ignoreAjaxAbort: true
  ).attach()

  $weekList = $(".week-list")

  minimumMinutes = 15

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

      minutes = ((initialHeight + deltaY) / stepHeightPx) * minimumMinutes
      remainder = minutes % minimumMinutes
      minutes = minutes - remainder

      if minimumMinutes < minutes <= 480
        $draggedElement.trigger "previewFromDrag", minutes: minutes

    $weekList.on "mouseup", (mouseupEvent) ->
      finalMouseX = mouseupEvent.screenX
      finalMouseY = mouseupEvent.screenY

      minutes = ($draggedElement.height() / stepHeightPx) * minimumMinutes

      remainder = minutes % minimumMinutes
      minutes = minutes - remainder

      if minimumMinutes < minutes <= 480
        $draggedElement.trigger "updateFromDrag", minutes: minutes

      $weekList.off "mousemove"
      $weekList.off "mouseup"