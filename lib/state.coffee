module.exports =
  class State
    list:  undefined

    constructor: (list) ->
      if list?
        @list = list
      else
        @list = []

    add: (id) =>
      console.log "list"
      console.log @list
      console.log typeof @list
      @list.push
        id:    id
        state: 0

    remove: (id) =>
      for i in [0...@list.length]
        if list[i].id is id
          n = i
          break
      @list.splice n, 1 if n?

    inc: (id) =>
      s.state++ for s in @list when s.id is id

    get: (id) =>
      return s.state for s in @list when s.id is id

    set: (id, state) =>
      s.state = state for s in @list when s.id is id

    happendBefore: (state) =>
      i = j = 0
      list2 = state.list
      res = true
      while i < @list.length and j < list2.length
        switch
          when @list[i].id < list2[j].id
            i++
          when @list[i].id > list2[j].id
            j++
          else
            if @list[i].state > list2[j].state
              res = false
            i++
            j++
      # console.log "happendBefore"
      # console.log @list
      # console.log list2
      # console.log res
      return res

    equals: (state) =>
      list2 = state.list
      return false if @list.length isnt list2.length
      for i in [0...@list.length]
        if @list[i].id isnt list2[i].id
          return false
        else
          if @list[i].state isnt list2[i].state
            return false
      return true