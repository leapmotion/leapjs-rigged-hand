TO_RAD = Math.PI / 180
TO_DEG = 1 / TO_RAD
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

# so far, so good
THREE.Quaternion.prototype.setFromVectors = (a, b)->
  axis = (new THREE.Vector3).crossVectors(a, b)
  angle = Math.acos(a.dot(b))
#  confirmed: the x axis flips sign when the hand flips
#  console.log axis.x > 0, axis.y > 0, axis.z > 0
#  if angle > 0
#    console.log 'positive'
#  else
#    console.log 'negative'
  @setFromAxisAngle(axis, angle)
#  @setFromAxisAngle(new THREE.Vector3(0,1,0), -5 * TO_RAD)
  @

# for some reason, we can't store custom properties on the Vector3
# we return an arrow and expect it to be passed back
THREE.Vector3.prototype.visualize = (scene, color)->
  if @_arrow
    @_arrow.setDirection(@)
  else
    @_arrow = new THREE.ArrowHelper(
      @,
      new THREE.Vector3(-10, 0, 0),
      10,
      color
    )
    scene.add @_arrow
  @



HEIGHT = window.innerHeight
WIDTH = window.innerWidth

renderer = new THREE.WebGLRenderer(alpha: true)
#renderer.setClearColor( 0x000000, 0)
renderer.setClearColor(0x000000, 1)
renderer.setSize(WIDTH, HEIGHT)
document.getElementById('threejs').appendChild(renderer.domElement)


camera = new THREE.PerspectiveCamera(
  90,
  WIDTH / HEIGHT,
  1,
  1000
)

camera.position.z = 5
camera.position.x = 0
camera.position.y = 15
camera.lookAt(new THREE.Vector3(0, 0, 0))

scene = new THREE.Scene()
scene.add(camera)

scene.add new THREE.AxisHelper(50)


scene.add new THREE.AmbientLight(0x444444)
#directionalLight = new THREE.DirectionalLight(  0xffffff, 1 )
#directionalLight.position.set( 10, -10, 10 );
#scene.add( directionalLight );

pointLight = new THREE.PointLight(0xFFffff)
pointLight.position = new THREE.Vector3(-20, 10, 0)
pointLight.lookAt new THREE.Vector3(0, 0, 0)
scene.add(pointLight)

rectangle = new THREE.Mesh(
  new THREE.CubeGeometry(
    4, 1, 8),
  new THREE.MeshPhongMaterial({
    color: 0x00ff00
  })
)
rectangle.position = new THREE.Vector3(0, 0, 0)
#scene.add(rectangle)
#rectangle.castShadow = false
#rectangle.receiveShadow = false
#
#
sphere = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshPhongMaterial({
      color: 0xff0000
    })
)
scene.add(sphere)


sphere2 = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshPhongMaterial({
      color: 0xcccc00
    })
)
scene.add(sphere2)

animation = undefined
handMesh = undefined


#(new THREE.JSONLoader).load 'javascripts/right-hand.json', (geometryWithBones, materials) ->
(new THREE.JSONLoader).load 'javascripts/14right.json', (geometryWithBones, materials) -> # have to manually set scale to 0.01 for this one
# JSONLoader expects vertices
# ObjectLoader seems to load empty objects for materials and geometries, tries to act on json.object rather than json.objects
  material = materials[0]
  material.skinning = true
#  material.visible = false

  THREE.GeometryUtils.center(geometryWithBones)
  handMesh = new THREE.SkinnedMesh(
    geometryWithBones, material
  )

  # First we apply a base transform, to make the hand oriented how we want it:
#  baseQuaternion = (new THREE.Quaternion).setFromEuler(new THREE.Euler(-Math.PI / 2, 0, -Math.PI / 2 , 'XYZ'))
#  baseQuaternion = (new THREE.Quaternion).setFromEuler(new THREE.Euler( - Math.PI / 4, -0.4, Math.PI  + 0.1, 'XYZ'))
#  baseQuaternion = (new THREE.Quaternion).setFromEuler(new THREE.Euler(0, Math.PI ,0, 'XYZ'))
#  handMesh.quaternion = baseQuaternion




  handMesh.castShadow = true
  handMesh.receiveShadow = true

  scene.add handMesh


  window.palm = handMesh.children[0].children[0].children[0] # technically, this bone is named wrist
  window.rigFingers = palm.children
  window.thumb = rigFingers[0]
  window.indexFinger = rigFingers[1]
  window.middleFinder = rigFingers[2]
  window.pinky = rigFingers[3]
  window.ringFinger = rigFingers[4]
  palm.matrixAutoUpdate = false
#  indexFinger.matrixAutoUpdate = false
  palm.visible = false

#  indexFinger.rotateX(40 * TO_RAD)


  palmNormal = (new THREE.Vector3)#.visualize(scene)
  palmDirection = (new THREE.Vector3)#.visualize(scene, 0xcc0022)
  zeroVector = new THREE.Vector3(0,0,0)

#  console.log(palm.parent.parent.position.length()

#  armVector = (new THREE.Vector3(1,0,-2)).visualize(scene, 0x3333ff)
#  debugger
#  armVector.normalize()
#  debugger
#  armVector.multiplyScalar()

  a = (new THREE.Vector3).visualize(scene)
  b = (new THREE.Vector3).visualize(scene, 0xcccccc)
  c = (new THREE.Vector3)#.visualize(scene)
  d = (new THREE.Vector3)#.visualize(scene)
  x = []
  xx = new THREE.Vector3();
#  a2 = (new THREE.Vector3( 1, 0, 0)).normalize().visualize(scene)
#  b2 = (new THREE.Vector3(-1, 0.2, 0)).normalize().visualize(scene)
#  rigFingers[1].children[0].children[0].quaternion.setFromVectors(a2, b2)
  renderer.render(scene, camera)

  lengthVals = []

  fingerLengths = [66.045, 63.635, 50.07, 63.65, 70.206, 67.6442, 71.8168, 72.3318, 72.6944, 72.9638, 73.1665, 73.312, 73.4207, 73.4988, 73.5561, 73.5991, 73.6301, 73.653, 73.6699, 73.6823, 73.6914, 73.698, 73.7029, 73.7065, 73.7091, 73.711, 73.7124, 73.7135, 73.7142, 73.7148, 73.7152, 73.7155, 73.7157, 73.7159, 73.716, 73.7161, 73.7162, 71.0263, 71.0264, 73.7163, 55.8858, 71.0431, 71.5765, 68.9647, 54.2636, 68.9809]
  avg = 0
  for num in fingerLengths
    avg += num
  console.log avg / fingerLengths.length

  Leap.loop (frame)->
    if leapHand = frame.hands[0]

      handMesh.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
      sphere.position.copy(handMesh.position)
      handMesh.position.sub ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(3.5)) # 70mm/20 = 3.5 units
      sphere2.position.copy(handMesh.position)

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
      palmNormal.fromArray(leapHand.palmNormal).multiplyScalar(-1)#.visualize()
      palmDirection.fromArray(leapHand.direction)#.visualize()
      palm.matrix.lookAt(palmDirection, zeroVector, palmNormal)
      palm.matrix.decompose(palm.position, palm.quaternion, palm.scale)
      palm.updateMatrixWorld(true)


      a.fromArray(leapHand.direction).visualize()
      # we get the vector from mcp to pip, so that it points away from palm direction
      # aka mcpDirection * -1
      Leap.vec3.subtract(x, leapFinger.pipPosition, leapFinger.mcpPosition)
      b.fromArray(x).normalize()#.visualize()
      rigFingers[i].quaternion.setFromVectors(b, a)
      rigFingers[i].quaternion.multiply(palm.quaternion.clone().inverse())
#      console.log(rigFingers[i].quaternion)
#      rigFingers[i].quaternion.multiply(palm.quaternion).normalize()


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

