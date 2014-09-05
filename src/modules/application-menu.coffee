Mole.module "ApplicationMenu", (Module, App) ->

  handleMenuAction = ->
    label = @label.replace(/\s/g, "-").toLowerCase()
    App.vent.trigger "menu:#{label}"

  menuItems = [
    { type: "separator" }
    {
      label: "New Entry"
      click: handleMenuAction
      key: "n"
      modifiers: "cmd"
    }
    {
      label: "Edit Entry"
      click: handleMenuAction
      key: "e"
      modifiers: "cmd"
    }
    {
      label: 'Logout'
      click: handleMenuAction
    }
  ]

  @addInitializer =>
    gui = require "nw.gui"

    nativeMenuBar = new gui.Menu type: "menubar"
    nativeMenuBar.createMacBuiltin "Mole"

    for menuItem in menuItems
      nativeMenuBar.items[1].submenu.append new gui.MenuItem menuItem

    # nativeMenuBar.append file
    App.options.nwWindow.menu = nativeMenuBar

    # Add Entry
    # Remove Entry
    # Edit Entry

    # Go To Today
    # Go Forward
    # Go Backwards

    # Log Out