TO_RAD = Math.PI / 180
TO_DEG = 1 / TO_RAD
zeroVector = new THREE.Vector3(0,0,0)
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

  localAxisLevel = (new THREE.Vector3(1,0,0))
  worldAxisLevel = (new THREE.Vector3).crossVectors(@parent.worldUp, @parent.worldDirection).normalize()
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

  localAxis =
    localAxisLevel
    .add(worldAxisLevel)
    .sub(@worldAxis)
    .normalize()

  @quaternion.setFromAxisAngle(localAxis, angle)
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
#camera.position.set(-8,6,-16)
camera.position.set(0,3,15)
camera.lookAt(new THREE.Vector3(0, 0, 0))

scene.add(camera)


animation = undefined
handMesh = undefined



`function  visualizeBones( whichMesh , mesh ){
     for( var i = 0; i < whichMesh.bones.length; i++ ){
       var bone = whichMesh.bones[i];
       if( bone.parent == whichMesh ){
         visualizeBone( bone , whichMesh, mesh );
       }
     }
   }

   function visualizeBone( bone , parent , mesh ){
     var m = mesh.clone();
     parent.add( m );
     m.position = bone.position;
     m.rotation = bone.rotation;
     m.quaternion = bone.quaternion;

     for( var i = 0 ; i < bone.children.length; i ++ ){
       var childBone = bone.children[i];
       visualizeBone( childBone , m , mesh );
     }
   }`


#(new THREE.JSONLoader).load 'javascripts/right-hand.json', (geometryWithBones, materials) ->
(new THREE.JSONLoader).load 'javascripts/14right.json', (geometryWithBones, materials) -> # have to manually set scale to 0.01 for this one
# JSONLoader expects vertices
# ObjectLoader seems to load empty objects for materials and geometries, tries to act on json.object rather than json.objects
  material = materials[0]
  material.skinning = true

  for bone in geometryWithBones.bones
    for pos, i in bone.pos
      bone.pos[i]  *= 100

  THREE.GeometryUtils.center(geometryWithBones)
  handMesh = new THREE.SkinnedMesh(
    geometryWithBones, material
  )
  handMesh.castShadow = true
  handMesh.receiveShadow = true

  visualizeBones(
    handMesh ,
    new THREE.Mesh(
      new THREE.IcosahedronGeometry( .5 , 1 ) ,
      new THREE.MeshNormalMaterial()
    )
  )

  scene.add handMesh

  window.forearm = handMesh.children[0]
  window.palm = handMesh.children[0].children[0].children[0] # technically, this bone is named wrist
  window.thumb = palm.children[0]
  window.indexFinger = palm.children[1]
  window.middleFinder = palm.children[2]
  window.ringFinger = palm.children[4]
  window.pinky = palm.children[3]
  # the bones are out of order in the model, so sort
  palm.children = [thumb, indexFinger, middleFinder, ringFinger, pinky]
  forearm.matrixAutoUpdate = false

  palm.worldUp         = (new THREE.Vector3).visualize(scene, 0xff0000)
  palm.worldDirection  = (new THREE.Vector3).visualize(scene, 0xffff00)

  armVector = (new THREE.Vector3(1,0,2)).normalize()#.visualize(scene, 0x3333ff)
  armVector.multiplyScalar(10)

  for rigFinger in palm.children
    rigFinger.worldDirection = new THREE.Vector3
    rigFinger.children[0].worldDirection = new THREE.Vector3
    rigFinger.children[0].children[0].worldDirection = new THREE.Vector3

    rigFinger.worldUp = new THREE.Vector3
    rigFinger.children[0].worldUp = new THREE.Vector3
    rigFinger.children[0].children[0].worldUp = new THREE.Vector3

    rigFinger.worldAxis = (new THREE.Vector3).visualize(scene, 0x00ff00)
    rigFinger.children[0].worldAxis = new THREE.Vector3
    rigFinger.children[0].children[0].worldAxis = new THREE.Vector3

    rigFinger.worldAxisReverse = (new THREE.Vector3).visualize(scene, 0x00ff00)
    rigFinger.children[0].worldAxisReverse = new THREE.Vector3
    rigFinger.children[0].children[0].worldAxisReverse = new THREE.Vector3

  indexFinger.worldUp.visualize(scene, 0x770000)
  indexFinger.worldDirection.visualize(scene, 0x777700)
  indexFinger.worldAxis.visualize(scene, 0x00ff00)

  renderer.render(scene, camera)


  j = 0

  Leap.loop (frame)->
    if leapHand = frame.hands[0]

#      yellowDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
#      redDot.position.copy(yellowDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(3.5)) # 70mm/20 = 3.5 units
#      armVector#.visualizeFrom(yellowDot.position)
      redDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
      yellowDot.position.copy(redDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(-1.5)) # 70mm/20 = 3.5 units

  
      # lookAt eye, target, up -> self position, target position, normal
      # of course, we just have a direction, and eye is used internall just to make a direction
      # z.subVectors( eye, target ).normalize();
      # so we hack in for now and set an eye of our direction and a target of 0,0,0
      # bone.update calls bone.updateMatrix calls matrix.compose(this.position, this.quaternion, this.scale)
      # matrixAutoUpdate must be false, in order for `updateMatrixWorld(force = true)` to be effective
  #      leapHand.palmNormal[2] *= -1
  #      leapHand.direction[2]  *= -1
#      palm.matrix.lookAt(palm.worldDirection, zeroVector, palm.worldUp)
#      palm.matrix.decompose(palm.position, palm.quaternion, palm.scale)
#      palm.updateMatrixWorld(true)

      palm.worldDirection.fromArray(leapHand.direction)
      palm.worldUp.fromArray(leapHand.palmNormal).multiplyScalar(-1)
  
      for leapFinger, i in leapHand.fingers
#        if i == 1
          # wrist -> mcp -> pip -> dip -> tip

        palm.children[i].worldDirection.subVectors(leapFinger.pipPosition, leapFinger.mcpPosition).normalize()
        palm.children[i].children[0].worldDirection.subVectors(leapFinger.dipPosition, leapFinger.pipPosition).normalize()
        palm.children[i].children[0].children[0].worldDirection.subVectors(leapFinger.tipPosition, leapFinger.dipPosition).normalize()

        # we set this in to local space by comparing rotation axis against the local x axis.
        palm.children[i].positionFromWorld()
        palm.children[i].children[0].positionFromWorld()
        palm.children[i].children[0].children[0].positionFromWorld()

      palm.worldUp.visualize()
      palm.worldDirection.visualize()
      indexFinger.worldUp.visualize()
      indexFinger.worldDirection.visualize()

#      if j == 0
      j++
      j = j % 60

      renderer.render(scene, camera)

