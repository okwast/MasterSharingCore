events = require 'events'
types = require './types'
State = require './state'

# This is a handler for conflicts.
# Conflicts are identified and solved.
module.exports =
  class ConflictManager

    constructor: ->

    handleConflicts: (conflicts, transform) =>
      for c in conflicts
        if transform.type is types.textChange
          @handleTextChangeConflicts c, transform

    # Gets a history, a client id and a transform
    # This function gets all the transforms beeing in conflict with
    # the given transform.
    getConflictingTransforms: (history, clientId, transform) ->
      return [] if history.length <= 0
      newTranforms = []
      for i in [history.length - 1..0]
        t = history[i]
        st = t.state
        if !st.list?
          st = new State st
        if transform.state.conflictingWith st, clientId
          newTranforms.push t
        else
          break
      return newTranforms

    # Changes the rows in a transform
    moveRow: (transform, count) ->
      transform.oldRange.start.row += count
      transform.oldRange.end.row   += count
      transform.newRange.start.row += count
      transform.newRange.end.row   += count

    # Calculates the difference in the number of rows
    # of the new text and the old text
    difRow: (transform) ->
      oldRow = transform.oldRange.end.row - transform.oldRange.start.row
      newRow = transform.newRange.end.row - transform.newRange.start.row
      return newRow - oldRow

    # Checks wether there is a conflict,
    # because of the rows
    checkRowConflict: (c, transform) ->
      if c.oldRange.start.row < transform.oldRange.start.row
        return true
      else
        if c.oldRange.start.row is transform.oldRange.start.row and
           c.oldRange.start.column <  transform.oldRange.start.column
          return true
        else
          return false

    fixRow: (c, transform) =>
      difRow = @difRow c
      @moveRow transform, difRow if difRow isnt 0

    # Changes the column entries in an transform
    moveCol: (transform, count, startAndEnd) ->
      transform.oldRange.start.column += count
      transform.oldRange.end.column   += count if startAndEnd
      transform.newRange.start.column += count
      transform.newRange.end.column   += count if startAndEnd

    difCol: (transform) ->
      return transform.newRange.end.column - transform.oldRange.end.column

    # Checks wether there is a conflict,
    # because of the columns
    checkColConflict: (c, transform) ->
      return c.newRange.end.row is transform.oldRange.start.row and
             c.newRange.end.column <  transform.oldRange.start.column

    # Fixes column problems
    fixCol: (c, transform) ->
      difCol = @difCol c

      hasLineBreaks = transform.newRange.end.row -
        transform.newRange.start.row

      @moveCol transform, difCol, !hasLineBreaks

    # Handles conflicts of textchange transforms
    handleTextChangeConflicts: (c, transform) =>
      if @checkRowConflict c, transform
        @fixRow c, transform

        if @checkColConflict c, transform
          @fixCol c, transform