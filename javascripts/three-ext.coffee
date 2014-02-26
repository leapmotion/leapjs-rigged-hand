window.TO_RAD = Math.PI / 180
window.TO_DEG = 1 / TO_RAD
window.zeroVector = new THREE.Vector3(0,0,0)
# accepts three points in two lines, with b being the join.
THREE.Quaternion.prototype.setFromPoints = (a, b, c)->
  @setFromVectors(
    (new THREE.Vector3).subVectors(a, b).normalize(),
    (new THREE.Vector3).subVectors(c, b).normalize()
  )

THREE.Vector3.prototype.quick = ->
  [
    @x.toPrecision(2)
    @y.toPrecision(2)
    @z.toPrecision(2)
  ]

window.vec3 = (x,y,z)->
  (new THREE.Vector3(x,y,z))

# weird (180 offset?) results for [-1, -0.5, 0] and [1,0.5,0]
## http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
#THREE.Quaternion.prototype.setFromVectors = (a, b)->
#  w = (new THREE.Vector3).crossVectors(a, b)
#  @set(1 + a.dot(b), w.x, w.y, w.z)
#  @normalize()
#  @_updateEuler() # not sure if this is important
#  @

# expects normalized vectors from world space, such as from the leap
# sets the bone's quaternion and saves bone.worldUp for later use
# this method could be super improved - acos and sin are theoretically unnecessary
THREE.Bone.prototype.positionFromWorld = ->
  directionDotParentDirection = @worldDirection.dot(@parent.worldDirection)
  angle = Math.acos directionDotParentDirection

  @localAxisLevel ||= (new THREE.Vector3(1,0,0))

  worldAxisLevel = (new THREE.Vector3).crossVectors(@parent.worldDirection, @parent.worldUp).normalize()
  @worldAxis.crossVectors(@parent.worldDirection, @worldDirection).normalize()
  @worldAxisReverse.crossVectors(@worldDirection, @parent.worldDirection).normalize()

#  angle = 10 * TO_RAD
#  worldAxis = new THREE.Vector3(0,1,0)
#  parentUp.set(0.1, 1, 0).normalize().visualize()

  # the behavior is correct, but we are consistently off by some small amount.
  # http://en.wikipedia.org/wiki/Rodrigues'_rotation_formula
  # v = palmNormal = parentUp
  # k = rotation axis = worldAxis
  @worldUp ||= new THREE.Vector3
  @worldUp.set(0,0,0)
    .add(@parent.worldUp.clone().multiplyScalar(directionDotParentDirection))
    .add((new THREE.Vector3).crossVectors(@worldAxis, @parent.worldUp).multiplyScalar(Math.sin(angle)))
    .add(@worldAxis.clone().multiplyScalar(@worldAxis.dot(@parent.worldUp) * (1 - directionDotParentDirection)))
    .normalize()

  
  
#  # now we test
#  testAngle = Math.acos(@worldUp.dot(parentUp))
#  console.log('angle, testAngle', (angle * TO_DEG).toPrecision(2), (testAngle * TO_DEG).toPrecision(2))
#
#  testAxis = (new THREE.Vector3).crossVectors(parentUp, @worldUp)
#  console.log('axis, testAxis', @worldAxis.quick(), testAxis.quick())
#  this test doesn't work at all - it should be close to 90° at all times.
#  console.log "error: #{Math.acos(@worldUp.dot(parentUp)) * TO_DEG - 90}"
#
  localAxis =
#    @localAxis ||
    @localAxisLevel.clone()
    .add(worldAxisLevel)
    .sub(@worldAxisReverse)
    .normalize()

#
#  unless @_localAxisArrow
#    @_localAxisArrow = new THREE.ArrowHelper(localAxis, zeroVector, 4, 0xffcc33)
#    @add @_localAxisArrow

  unless @_worldDirectionArrow
    @_worldDirectionArrow = new THREE.ArrowHelper(@worldDirection, zeroVector, 4, 0x99cc33)
    @add @_worldDirectionArrow

  unless @_parentWorldDirectionArrow
    @_parentWorldDirectionArrow = new THREE.ArrowHelper(@parent.worldDirection, zeroVector, 4, 0xff9933)
    console.log @parent.worldDirection.quick(), @position.quick()
    @add @_parentWorldDirectionArrow
#
#  unless @_worldAxisArrow
#    @_worldAxisArrow = new THREE.ArrowHelper(@worldAxisReverse, zeroVector, 2, 0xccff33)
#    @add @_worldAxisArrow

  deltaPos = undefined
  unless @_directionArrow
    if @children[0]
      deltaPos = vec3().subVectors(@children[0].position, @position)
      @_directionArrow = new THREE.ArrowHelper(
        deltaPos,
        zeroVector,
        deltaPos.length() * 100
      ,  0x33ccff)
    console.log "#{@name} position", @position.quick(), "#{@children[0].name} child position", @children[0].position.quick(), "length", deltaPos.length().toPrecision(2)
    @add @_directionArrow

#  unless @yArrow
#    if @children[0]
#      @yArrow = vec3(0,1,0).visualize(this, 0x00ff00, 3)
#
#  unless @xArrow
#    if @children[0]
#      @xArrow = vec3(1,0,0).visualize(this, 0xff0000, 3)
#
#  unless @zArrow
#    if @children[0]
#      @zArrow = vec3(0,0,1).visualize(this, 0x0000ff, 3)

  @quaternion.setFromAxisAngle(localAxis, angle)
  @

# for some reason, we can't store custom properties on the Vector3
# we return an arrow and expect it to be passed back
THREE.Vector3.prototype.visualize = (parent, color, length)->
  length ||= 10
  if @_arrow
    @_arrow.setDirection(@)
  else
    @_arrow = new THREE.ArrowHelper(
      @, # direction
      new THREE.Vector3(0,0,0), # origin
#      parent.position, # origin
      length, # length
      color
    )
    parent.add @_arrow
  @

THREE.Vector3.prototype.visualizeFrom = (position)->
  @_arrow.position = position
  @

THREE.Vector3.prototype.visualizeFromPosition = ->
  @_arrow.position = @position
  @

THREE.Scene.prototype.scene = THREE.SkinnedMesh.prototype.scene = THREE.Bone.prototype.scene = THREE.Object3D.scene = ->
  if @parent == undefined
    return this
  else
    return @parent.scene()

THREE.Bone.prototype.visualizeRecursive = THREE.Object3D.prototype.visualizeRecursive = ->
  @_visualizeX ||= new THREE.Vector3
  @_visualizeY ||= new THREE.Vector3
  @_visualizeZ ||= new THREE.Vector3

  l = 3
  if @children[0]
    l = vec3().subVectors(@children[0].position, @position)#.length()
  #  @_visualizeX.set(1,0,0).applyQuaternion(@_quaternion).visualize(this, 'red', 3)
  #  @_visualizeY.set(0,1,0).applyQuaternion(@_quaternion).visualize(this, 0x00ff00, 3)
  #  @_visualizeZ.set(0,0,1).applyQuaternion(@_quaternion).visualize(this, 0x0000ff, 3)
  @_visualizeX.set(1,0,0).visualize(this, 'red', l.x)
  @_visualizeY.set(0,1,0).visualize(this, 0x00ff00, l.y)
  @_visualizeZ.set(0,0,1).visualize(this, 0x0000ff, l.z)
#  debugger

  for child in @children
    unless child instanceof THREE.ArrowHelper
      child.visualizeRecursive()