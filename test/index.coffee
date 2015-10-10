chai = require('chai')
stateClass = require '../lib/state'

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

  it 'in conflict', ->
    state1 = new stateClass([1, 1, 2])
    state2 = new stateClass([2, 1, 1])
    expect(state1.conflictingWith state2).to.be.true
