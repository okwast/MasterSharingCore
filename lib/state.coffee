# This is the class of the statevector
# The variable list is a list of number values.
# Every number represents the state of the client with that index as id

module.exports =
  class State
    list:  []

    constructor: (list) ->
      if list?
        @list = list.slice()
      else
        @list = []

    add: (id) =>
      @list[id] = 0

    remove: (id) =>
      @list[id] = 0

    inc: (id) =>
      @list[id]++

    get: (id) =>
      @list[id]

    set: (id, clientState) =>
      @list[id] = clientState

    conflictingWith: (state, id) =>
      list2 = state.list
      return true if @list.length isnt list2.length
      for i in [0...@list.length]
        if i is id
          return true if !(@list[i]? and list2[i]?)
          return true if @list[i] - 1 isnt list2[i]
        else
          if @list[i]? and list2[i]?
            return true if @list[i] < list2[i]
          else
            return true if @list[i]? or list2[i]?
      return false

    directFollowerOf: (state, id) ->
      list2 = state.list
      return false if @list.length isnt list2.length
      for i in [0...@list.length]
        if i is id
          return false if !(@list[i]? and list2[i]?)
          return false if (@list[i] - 1) isnt list2[i]
        else
          if @list[i]? and list2[i]?
            return false if @list[i] isnt list2[i]
          else
            return false if @list[i]? or list2[i]?
      return true

    equals: (state) =>
      list2 = state.list
      return false if @list.length isnt list2.length
      for i in [0...@list.length]
        return false if @list[i] isnt list2[i]
      return true