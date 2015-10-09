events = require 'events'
types = require './types'

module.exports =
  class ConflictManager

    constructor: ->

    handleConflicts: (conflicts, transform) =>
      for c in conflicts
        if transform.type is types.textChange
          @handleTextChangeConflicts c, transform

    moveRow: (transform, count) ->
      transform.oldRange.start += count
      transform.oldRange.end   += count
      transform.newRange.start += count
      transform.newRange.end   += count

    difRow: (transform) ->
      oldRow = transform.oldRange.end.row - transform.oldRange.start.row
      newRow = transform.newRange.end.row - transform.newRange.start.row
      newRow - oldRow

    fixRow: (c, transform) =>
      difRow = @difRow c
      @moveRow transform, difRow if difRow isnt 0

    fixCol: (c, transform) ->
      difCol = c.oldRange.end.column - c.newRange.end.column

      transform.oldRange.start.column += difCol

      if transform.oldRange.start.row == transform.oldRange.end.row
        transform.oldRange.end.column += difCol

      if transform.oldRange.start.row == transform.newRange.start.row
        transform.newRange.start.column += difCol

      if transform.oldRange.start.row == transform.newRange.end.row
        transform.newRange.end.column += difCol

    handleTextChangeConflicts: (c, transform) =>
      if c.oldRange.start.row < transform.oldRange.start.row
        @fixRow c, transform
      else if c.oldRange.start.row == transform.oldRange.start.row
        if c.oldRange.start.column <= transform.oldRange.start.column
          @fixRow c, transform
          @fixCol c, transform