chai = require('chai')
stateClass = require '../lib/state'
conflictManager = require '../lib/conflictManager'

chai.should()
expect = chai.expect

describe 'States', ->
  state1 = new stateClass()
  it 'state list is empty', ->
    state1.list.length.should.equal 0

  it 'adding an id to state', ->
    state1.add 0
    state1.list[0].should.equal 0

  it 'state is equal to itself', ->
    expect(state1.equals state1).to.be.true

  it 'incrementing', ->
    state1.inc 0
    state1.get(0).should.equal 1

  it 'copy states', ->
    state1 = new stateClass([1, 1, 1])
    state2 = new stateClass([1, 1, 1])
    expect(state1.equals state2).to.be.true

  it 'different states', ->
    state1 = new stateClass([1, 2, 1])
    state2 = new stateClass([1, 1, 1])
    expect(state1.equals state2).to.be.false

  it 'direct Follower of', ->
    state1 = new stateClass([1, 2, 1])
    state2 = new stateClass([1, 1, 1])
    expect(state1.directFollowerOf state2, 1).to.be.true

  it 'not direct Follower of', ->
    state1 = new stateClass([1, 1, 1])
    state2 = new stateClass([1, 2, 1])
    expect(state1.directFollowerOf state2, 1).to.be.false

  it 'not in conflict', ->
    state1 = new stateClass([1, 2, 1])
    state2 = new stateClass([1, 1, 1])
    expect(state1.conflictingWith state2, 1).to.be.false

  it 'not in conflict 2', ->
    state1 = new stateClass([1, 3, 2])
    state2 = new stateClass([1, 2, 2])
    expect(state1.conflictingWith state2, 1).to.be.false

  it 'in conflict', ->
    state1 = new stateClass([1, 1, 1])
    state2 = new stateClass([1, 2, 1])
    expect(state1.conflictingWith state2).to.be.true

  it 'in conflict 2', ->
    state1 = new stateClass([1, 1, 2])
    state2 = new stateClass([2, 1, 1])
    expect(state1.conflictingWith state2, 2).to.be.true


describe 'Conflicts', ->
  cm = new conflictManager()
  it 'no list, no conflicts', ->
    cm.getConflictingTransforms([]).length.should.equal 0

  it 'no conflict', ->
    history = [
      {state: new stateClass [1,1,1]}
      {state: new stateClass [1,2,1]}
      {state: new stateClass [1,2,2]}
    ]
    console.log 'history'
    console.log history
    transform = {}
    transform.state = new stateClass [1,3,2]
    cm.getConflictingTransforms(history, 1, transform).length.should.equal 0

  it 'one conflict', ->
    history = [
      {state: new stateClass [1,1,1]}
      {state: new stateClass [1,2,1]}
      {state: new stateClass [1,2,2]}
    ]
    console.log 'history'
    console.log history
    transform = {}
    transform.state = new stateClass [2,2,1]
    cm.getConflictingTransforms(history, 1, transform).length.should.equal 1

  it 'two conflicts', ->
    history = [
      {state: new stateClass [1,1,1]}
      {state: new stateClass [1,2,1]}
      {state: new stateClass [1,2,2]}
    ]
    console.log 'history'
    console.log history
    transform = {}
    transform.state = new stateClass [2,1,1]
    cm.getConflictingTransforms(history, 1, transform).length.should.equal 2