TO_RAD = Math.PI / 180
TO_DEG = 1 / TO_RAD
zeroVector = new THREE.Vector3(0,0,0)
# accepts three points in two lines, with b being the join.
THREE.Quaternion.prototype.setFromPoints = (a, b, c)->
  @setFromVectors(
    (new THREE.Vector3).subVectors(a, b).normalize(),
    (new THREE.Vector3).subVectors(c, b).normalize()
  )
# weird (180 offset?) results for [-1, -0.5, 0] and [1,0.5,0]
## http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
#THREE.Quaternion.prototype.setFromVectors = (a, b)->
#  w = (new THREE.Vector3).crossVectors(a, b)
#  @set(1 + a.dot(b), w.x, w.y, w.z)
#  @normalize()
#  @_updateEuler() # not sure if this is important
#  @

# expects normalized vectors:
THREE.Quaternion.prototype.setFromVectors = (childDirection, parentDirection, parentUp)->
  angle = Math.acos(childDirection.dot(parentDirection))

  # this is too hard to explain:
  axis =
    # local space hand rotation axis
    (new THREE.Vector3(1,0,0))
    .add(
      # world space hand curl axis - the zero-mark
      (new THREE.Vector3).crossVectors(parentUp,      parentDirection).normalize()
    ).sub(
      # world space hand curl axis
      (new THREE.Vector3).crossVectors(childDirection, parentDirection).normalize()
    ).normalize()

  @setFromAxisAngle(axis, angle)
  @

#
#  angle = Math.acos(firstBoneDirection.dot(palmDirection))
#  axis.crossVectors(firstBoneDirection, palmDirection).normalize()#.visualize() # normalize here appears unnecessary?
#  normalAxis.crossVectors(palmNormal, palmDirection).normalize()#.visualize()
#  axis.sub(normalAxis)
#  rigFingers[i].quaternion.setFromAxisAngle(new THREE.Vector3(1,0,0).sub(axis).normalize(), angle)

# for some reason, we can't store custom properties on the Vector3
# we return an arrow and expect it to be passed back
THREE.Vector3.prototype.visualize = (scene, color)->
  if @_arrow
    @_arrow.setDirection(@)
  else
    @_arrow = new THREE.ArrowHelper(
      @,
      new THREE.Vector3(-7, 0, 0),
      10,
      color
    )
    scene.add @_arrow
  @

THREE.Vector3.prototype.visualizeFrom = (origin)->
  @_arrow.position.copy(origin)
  @


HEIGHT = window.innerHeight
WIDTH = window.innerWidth
scene = new THREE.Scene()

renderer = new THREE.WebGLRenderer(alpha: true)
#renderer.setClearColor( 0x000000, 0)
renderer.setClearColor(0x000000, 1)
renderer.setSize(WIDTH, HEIGHT)
document.getElementById('threejs').appendChild(renderer.domElement)


scene.add new THREE.AxisHelper(50)


scene.add new THREE.AmbientLight(0x888888)
#directionalLight = new THREE.DirectionalLight(  0xffffff, 1 )
#directionalLight.position.set( 10, -10, 10 );
#scene.add( directionalLight );

pointLight = new THREE.PointLight(0xFFffff)
pointLight.position = new THREE.Vector3(-20, 10, 0)
pointLight.lookAt new THREE.Vector3(0, 0, 0)
scene.add(pointLight)

#rectangle = new THREE.Mesh(
#  new THREE.CubeGeometry(
#    4, 1, 8),
#  new THREE.MeshPhongMaterial({
#    color: 0x00ff00
#  })
#)
#rectangle.position = new THREE.Vector3(0, 0, 0)
#rectangle.matrix.lookAt(new THREE.Vector3(1, 1, 0), zeroVector, rectangle.up)
#rectangle.matrix.decompose(rectangle.position, rectangle.quaternion, rectangle.scale)
#scene.add(rectangle)

redDot = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshPhongMaterial({
      color: 0xff0000
    })
)
scene.add(redDot)


yellowDot = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshPhongMaterial({
      color: 0xcccc00
    })
)
scene.add(yellowDot)


camera = new THREE.PerspectiveCamera(
  90,
  WIDTH / HEIGHT,
  1,
  1000
)
camera.position.set(-8,6,-16)
#camera.position.set(0,3,15)
camera.lookAt(new THREE.Vector3(0, 0, 0))

scene.add(camera)


animation = undefined
handMesh = undefined


(new THREE.JSONLoader).load 'javascripts/right-hand.json', (geometryWithBones, materials) ->
#(new THREE.JSONLoader).load 'javascripts/14right.json', (geometryWithBones, materials) -> # have to manually set scale to 0.01 for this one
# JSONLoader expects vertices
# ObjectLoader seems to load empty objects for materials and geometries, tries to act on json.object rather than json.objects
  material = materials[0]
  material.skinning = true

  THREE.GeometryUtils.center(geometryWithBones)
  handMesh = new THREE.SkinnedMesh(
    geometryWithBones, material
  )


  handMesh.castShadow = true
  handMesh.receiveShadow = true

  scene.add handMesh

  window.forearm = handMesh.children[0]
  window.palm = handMesh.children[0].children[0].children[0] # technically, this bone is named wrist
  window.rigFingers = palm.children
  window.thumb = rigFingers[0]
  window.indexFinger = rigFingers[1]
  window.middleFinder = rigFingers[2]
  window.pinky = rigFingers[3]
  window.ringFinger = rigFingers[4]
#  palm.matrixAutoUpdate = false
#  indexFinger.matrixAutoUpdate = false
  forearm.matrixAutoUpdate = false
#  palm.parent = undefined
#
  palmNormalUp = (new THREE.Vector3)#.visualize(scene, 0x008899)
  palmNormal = (new THREE.Vector3).visualize(scene, 0x008899)
  palmDirection = (new THREE.Vector3)#.visualize(scene, 0xcc0022)

#  ringFinger.children[0].children[0].rotateX(50 * TO_RAD)
#
#  middleFinder.children[0].rotateX(50 * TO_RAD)
#  middleFinder.children[0].children[0].rotateX(50 * TO_RAD)
#
#  indexFinger.rotateX(50 * TO_RAD)
#  indexFinger.rotateX(30 * TO_RAD)
#  indexFinger.matrix.makeRotationFromQuaternion(indexFinger.quaternion)
#  indexFinger.children[0].children[0].rotateX(50 * TO_RAD)
#  indexFinger.children[0].children[0].children[0].rotateX(50 * TO_RAD)

  armVector = (new THREE.Vector3(1,0,2)).normalize().visualize(scene, 0x3333ff)
  armVector.multiplyScalar(10)

  palmDirection = (new THREE.Vector3).visualize(scene) #yellow
  firstBoneDirection = (new THREE.Vector3).visualize(scene, 0xff0000) # grey
  secondBoneDirection = (new THREE.Vector3).visualize(scene, 0xff9944)
  thirdBoneDirection = (new THREE.Vector3).visualize(scene)
  firstBoneNormal = (new THREE.Vector3).visualize(scene, 0x00aa44)
  secondBoneNormal = (new THREE.Vector3).visualize(scene, 0x009966)
  thirdBoneNormal = (new THREE.Vector3).visualize(scene, 0x009988)

  firstBoneNormal.set(0,1,0)
  secondBoneNormal.set(0,1,0)
  thirdBoneNormal.set(0,1,0)
  indexFinger.localToWorld(firstBoneNormal).normalize().visualize()

  renderer.render(scene, camera)

  lengthVals = []

  fingerLengths = [66.045, 63.635, 50.07, 63.65, 70.206, 67.6442, 71.8168, 72.3318, 72.6944, 72.9638, 73.1665, 73.312, 73.4207, 73.4988, 73.5561, 73.5991, 73.6301, 73.653, 73.6699, 73.6823, 73.6914, 73.698, 73.7029, 73.7065, 73.7091, 73.711, 73.7124, 73.7135, 73.7142, 73.7148, 73.7152, 73.7155, 73.7157, 73.7159, 73.716, 73.7161, 73.7162, 71.0263, 71.0264, 73.7163, 55.8858, 71.0431, 71.5765, 68.9647, 54.2636, 68.9809]
  avg = 0
  for num in fingerLengths
    avg += num
  console.log avg / fingerLengths.length

  j = 0


  Leap.loop (frame)->
    if leapHand = frame.hands[0]

#      yellowDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
#      redDot.position.copy(yellowDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(3.5)) # 70mm/20 = 3.5 units
      redDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
      yellowDot.position.copy(redDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(-1.5)) # 70mm/20 = 3.5 units
      armVector.visualizeFrom(yellowDot.position)

#      # note: it looks like lookAt only changes certain elements in the matrix, so technically this could be cleaned up
#      forearm.matrix.lookAt(armVector.clone().multiplyScalar(-1), zeroVector, new THREE.Vector3(0,1,0))
#      forearm.matrix.decompose(forearm.position, forearm.quaternion, forearm.scale)
#      forearm.position.copy(yellowDot.position).add(armVector)

#      if lengthVals.indexOf(leapHand.fingers[2].length) == -1
#        lengthVals.push(leapHand.fingers[2].length)
#        console.log lengthVals


      # putting this before palm, so that it's call to updateMatrixWorld will be used
#      for leapFinger, i in leapHand.fingers
      i = 1
      leapFinger = leapHand.fingers[i]

      # wrist -> mcp -> pip -> dip

#      # like an ordinary day
#      rigFingers[i].matrix.compose( rigFingers[i].position, rigFingers[i].quaternion, rigFingers[i].scale )
#
#      # except we reverse parenting:
#      parentMatrixWorldInverse = rigFingers[i].parent.matrixWorld.clone()
#      parentMatrixWorldInverse.getInverse(parentMatrixWorldInverse)
#      rigFingers[i].matrixWorld.multiplyMatrices( parentMatrixWorldInverse, rigFingers[i].matrix )


      # lookAt eye, target, up -> self position, target position, normal
      # of course, we just have a direction, and eye is used internall just to make a direction
      # z.subVectors( eye, target ).normalize();
      # so we hack in for now and set an eye of our direction and a target of 0,0,0
      # bone.update calls bone.updateMatrix calls matrix.compose(this.position, this.quaternion, this.scale)
      # matrixAutoUpdate must be false, in order for `updateMatrixWorld(force = true)` to be effective
#      leapHand.palmNormal[2] *= -1
#      leapHand.direction[2]  *= -1
      palmNormalUp.fromArray(leapHand.palmNormal).multiplyScalar(-1)#.visualize()
      palmNormal.fromArray(leapHand.palmNormal)#.visualize()
      palmDirection.fromArray(leapHand.direction)#.visualize()
      palm.matrix.lookAt(palmDirection, zeroVector, palmNormalUp)
      palm.matrix.decompose(palm.position, palm.quaternion, palm.scale)
      palm.updateMatrixWorld(true)
#      palmDirectionQuaternion = (new THREE.Quaternion).setFromVectors(palmDirection, new THREE.Vector3(0,1,0)).normalize()
#      palmNormalQuaternion = (new THREE.Quaternion).setFromVectors(palmNormal, new THREE.Vector3(0,1,0)).normalize()

      firstBoneDirection.subVectors(leapFinger.pipPosition, leapFinger.mcpPosition).normalize()#.visualize()
      secondBoneDirection.subVectors(leapFinger.dipPosition, leapFinger.pipPosition).normalize()#.visualize()
      thirdBoneDirection.subVectors(leapFinger.tipPosition, leapFinger.dipPosition).normalize()#.visualize()
#      rigFingers[i].quaternion.setFromVectors(firstBoneDirection, palmDirection)#.multiply(palm.quaternion).multiply(palm.quaternion)
#      rigFingers[i].quaternion.setFromEuler( new THREE.Euler(angle, 0, 0) ) # √


      firstBoneNormal.set(1,0,0)
      secondBoneNormal.set(0,1,0)
      thirdBoneNormal.set(0,1,0)

      # we set this in to local space by comparing rotation axis against the local x axis.
#      debugger
      rigFingers[i].quaternion.setFromVectors(firstBoneDirection, palmDirection, palmNormal)
#      rigFingers[i].updateMatrixWorld(true)
#      rigFingers[i].localToWorld(firstBoneNormal).normalize().visualize()
      rigFingers[i].children[0].quaternion.setFromVectors(secondBoneDirection, firstBoneDirection, palmNormal)
#      rigFingers[i].children[0].localToWorld(secondBoneNormal).normalize().visualize()
      rigFingers[i].children[0].children[0].quaternion.setFromVectors(thirdBoneDirection, secondBoneDirection, palmNormal)







#
      if j == 0
#        console.log firstBoneNormal
        # hoping randomly that z is roll. we test to see if roll changes much
        # if it does, we need to make sure we're getting the normal (up) of the bone, for cross product
        console.log rigFingers[i].quaternion._euler._z if Math.abs(rigFingers[i].quaternion._euler._z) > 10 * TO_RAD
#        console.log rigFingers[i].quaternion.toArray()
#        console.log firstBoneDirection.dot(palmDirection)
      j++
      j = j % 60

#      rigFingers[i].quaternion.setFromVectors(
#        THREE.Vector3(0,0,0),
#      )
#      rigFingers[i].matrix.lookAt(a,b, new THREE.Vector3(0,1,0))
#      angleDifference = (new THREE.Vector3).subVectors(b,a).normalize()

#      rigFingers[i].matrix.lookAt(b, zeroVector, palmNormal.add(angleDifference).normalize())
#      rigFingers[i].updateMatrixWorld(true)

#      rigFingers[i].children[0].quaternion.setFromVectors(b, a)
#      rigFingers[i].children[0].children[0].quaternion.setFromVectors(b, a)
#      rigFingers[i].children[0].children[0].children[0].quaternion.setFromVectors(b,a)

#      Leap.vec3.subtract(x, leapFinger.pipPosition, leapFinger.mcpPosition)
#      b.fromArray(x).normalize()#.visualize()
#      rigFingers[i].children[0].quaternion.setFromVectors(a, b)
#
#      Leap.vec3.subtract(x, leapFinger.dipPosition, leapFinger.pipPosition)
#      c.fromArray(x).normalize()#.visualize()
#      rigFingers[i].children[0].children[0].quaternion.setFromVectors(b.multiplyScalar(-1), c)
#
#      Leap.vec3.subtract(x, leapFinger.tipPosition, leapFinger.dipPosition)
#      d.fromArray(x).normalize()#.visualize()
#      rigFingers[i].children[0].children[0].children[0].quaternion.setFromVectors(c.multiplyScalar(-1), d)

      renderer.render(scene, camera)

