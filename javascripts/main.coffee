HEIGHT = window.innerHeight
WIDTH = window.innerWidth
scene = new THREE.Scene()

renderer = new THREE.WebGLRenderer(alpha: true)
#renderer.setClearColor( 0x000000, 0)
renderer.setClearColor(0x000000, 1)
renderer.setSize(WIDTH, HEIGHT)
document.getElementById('threejs').appendChild(renderer.domElement)

axis = new THREE.AxisHelper(5)
scene.add axis


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

#redDot = new THREE.Mesh(
#  new THREE.SphereGeometry(1),
#  new THREE.MeshPhongMaterial({
#      color: 0xff0000
#    })
#)
#scene.add(redDot)
#
#
#yellowDot = new THREE.Mesh(
#  new THREE.SphereGeometry(1),
#  new THREE.MeshPhongMaterial({
#      color: 0xcccc00
#    })
#)
#scene.add(yellowDot)


window.camera = new THREE.PerspectiveCamera(
  90,
  WIDTH / HEIGHT,
  1,
  1000
)
cameraPositions = {
  back: [0,0,-10]
#  back: [-6,4,-14]
  front: [0,3,15]
  rightSide: [25,0,0]
  top: [0,14,0]
}
cameraPosition = 'top'
renderer.domElement.onclick = ->
  camera.position.fromArray(cameraPositions[cameraPosition])
  camera.lookAt(new THREE.Vector3(0, 0, 0))
  if cameraPosition == 'front' then cameraPosition = 'back' else cameraPosition = 'front'
  renderer.render(scene, camera)
renderer.domElement.click()

scene.add(camera)


animation = undefined
handMesh = undefined


text = new THREE.Mesh(new THREE.TextGeometry('Y AXIS', {
    size: 0.5,
    height: 0.2
  }),
  new THREE.MeshBasicMaterial({ color: 0xffffff })
)

text.position.x = axis.geometry.vertices[1].x;
text.position.y = axis.geometry.vertices[1].y;
text.position.z = axis.geometry.vertices[1].z;
text.rotation = camera.rotation;
scene.add(text)


visualizeBones = ( whichMesh ) ->
  for child in whichMesh.children
     visualizeBone( child , whichMesh );

visualizeBone =( bone , parentMesh ) ->
  length = if bone.children[0] then bone.children[0].position.length() else 0.2
  console.log bone.name, length
  m = new THREE.Mesh(
       new THREE.CubeGeometry(.4, .2, length),
       new THREE.MeshPhongMaterial(color: 0x00ff00)
  )
  parentMesh.add( m )
  m.position = bone.position
  m.quaternion = bone.quaternion

  parentMesh.add new THREE.AxisHelper(1)

  for child in bone.children
   visualizeBone( child, m  )

#(new THREE.JSONLoader).load 'javascripts/right-hand.json', (geometryWithBones, materials) ->
(new THREE.JSONLoader).load 'javascripts/14right.json', (geometryWithBones, materials) -> # have to manually set scale to 0.01 for this one
#(new THREE.JSONLoader).load 'javascripts/hand_rig.json', (geometryWithBones, materials) -> # have to manually set scale to 0.01 for this one
# JSONLoader expects vertices
# ObjectLoader seems to load empty objects for materials and geometries, tries to act on json.object rather than json.objects
  material = materials[0]
  material.skinning = true
  material.wireframe = true

#  THREE.GeometryUtils.center(geometryWithBones)
  handMesh = new THREE.SkinnedMesh(
    geometryWithBones, material
  )
  handMesh.castShadow = true
  handMesh.receiveShadow = true
#  handMesh.visible = false

  visualizeBones(handMesh)

  scene.add handMesh

#  window.forearm = handMesh.children[0]
  window.palm = handMesh.children[0].children[0].children[0] # technically, this bone is named wrist
#  window.palm = handMesh.children[0].children[0]
  window.thumb = palm.children[0]
  window.indexFinger = palm.children[1]
  window.middleFinger = palm.children[2]
  # switch ring and finger when using 14right.json
#  window.ringFinger = palm.children[4]
#  window.pinky = palm.children[3]
  window.ringFinger = palm.children[3]
  window.pinky = palm.children[4]
  # the bones are out of order in the model, so sort
#  palm.children = [thumb, indexFinger, middleFinder, ringFinger, pinky]
#  forearm.matrixAutoUpdate = false
#  palm.matrixAutoUpdate = false

#  thumb.localAxisLevel = (new THREE.Vector3(0,1,0)).visualize(scene, 0x0000ff)
#  thumb.localAxisLevel = (new THREE.Vector3(17.672, -6.987, 27.543)).visualize(scene, 0x0000ff)
  thumb.localAxisLevel = (new THREE.Vector3(0,0,1)).visualize(scene, 0x0000ff)


  armVector = (new THREE.Vector3(1,0,2)).normalize()#.visualize(scene, 0x3333ff)
  armVector.multiplyScalar(10)

  # initialize
  for rigFinger in palm.children
    rigFinger.mip = rigFinger.children[0]
    rigFinger.dip = rigFinger.children[0].children[0]

#    rigFinger.add new THREE.AxisHelper(1)
#    rigFinger.mip.add new THREE.AxisHelper(1)
#    rigFinger.dip.add new THREE.AxisHelper(1)
#    rigFinger.add  new THREE.Mesh(
#      new THREE.CubeGeometry(.4, .2, 0.8),
#      new THREE.MeshPhongMaterial(color: 0x00ff00)
#    )
#    m = new THREE.Mesh(
#      new THREE.CubeGeometry(.4, .2, 0.8),
#      new THREE.MeshPhongMaterial(color: 0x00ff00)
#    )
#    m.position = rigFinger.position
#    debugger
#    rigFinger.mip.add m

    rigFinger.worldDirection = (new THREE.Vector3)#.visualize(scene, 0x444466).visualizeFrom(rigFinger.position)
    rigFinger.mip.worldDirection = (new THREE.Vector3)#.visualize(scene, 0x444466).visualizeFrom(rigFinger.children[0])
    rigFinger.dip.worldDirection = (new THREE.Vector3)#.visualize(scene, 0x444466).visualizeFrom(rigFinger.children[0].children[0])

    rigFinger.worldUp = new THREE.Vector3
    rigFinger.mip.worldUp = new THREE.Vector3
    rigFinger.dip.worldUp = new THREE.Vector3

    rigFinger.worldAxis = (new THREE.Vector3)#.visualize(scene, 0x00ff00)
    rigFinger.mip.worldAxis = new THREE.Vector3
    rigFinger.dip.worldAxis = new THREE.Vector3

    rigFinger.worldAxisReverse =    (new THREE.Vector3(0,0,1))#.visualize(scene, 0x00ff00)
    rigFinger.mip.worldAxisReverse = new THREE.Vector3(0,0,1)
    rigFinger.dip.worldAxisReverse = new THREE.Vector3(0,0,1)

  palm.worldUp         = (new THREE.Vector3).visualize(palm, 0xff0000)
#  arrow = (new THREE.ArrowHelper(palm.worldUp, zeroVector, 10, 0xff0000))
#  arrow.label 'palm world up'
#  palm.add arrow

  palm.worldDirection  = (new THREE.Vector3).visualize(palm, 0xffff00)
#  arrow2 = (new THREE.ArrowHelper(palm.worldDirection, zeroVector, 10, 0xffff00))
#  arrow2.label 'palm world direction'
#  palm.add arrow2
#  indexFinger.worldUp.visualize(palm, 0x770000)
#  indexFinger.worldDirection.visualize(palm, 0x777700)
#  indexFinger.worldAxis.visualize(palm, 0x00ff00)

  renderer.render(scene, camera)

  thumb.localAxis =     vec3(0,0,0).normalize()
  thumb.mip.localAxis = vec3(1,0,0).normalize()
  thumb.dip.localAxis = vec3(1,0,0).normalize()

  indexFinger.localAxis =     vec3(1,0,-0.2).normalize()
  indexFinger.mip.localAxis = vec3(1,0,-0.2).normalize()
  indexFinger.dip.localAxis = vec3(1,0,-0.2).normalize()

  middleFinger.localAxis =     vec3(1,0,0).normalize()
  middleFinger.mip.localAxis = vec3(1,0,0).normalize()
  middleFinger.dip.localAxis = vec3(1,0,0).normalize()

  ringFinger.localAxis =     vec3(1,0,0.1).normalize()
  ringFinger.mip.localAxis = vec3(1,0,0.1).normalize()
  ringFinger.dip.localAxis = vec3(1,0,0.1).normalize()

  pinky.localAxis =     vec3(1,0,0.2).normalize()
  pinky.mip.localAxis = vec3(1,0,0.2).normalize()
  pinky.dip.localAxis = vec3(1,0,0.2).normalize()
#  thumb.localAxis = vec3(19,-56,-20).normalize()


  window.j = 0

  Leap.loop (frame)->
    if leapHand = frame.hands[0]

#      yellowDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
#      redDot.position.copy(yellowDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(3.5)) # 70mm/20 = 3.5 units
#      armVector#.visualizeFrom(yellowDot.position)
#      redDot.position.fromArray(leapHand.stabilizedPalmPosition).divideScalar(20)
#      yellowDot.position.copy(redDot.position).add ( (new THREE.Vector3()).fromArray(leapHand.direction).multiplyScalar(-1.5)) # 70mm/20 = 3.5 units

      palm.worldDirection.fromArray(leapHand.direction)
      palm.worldUp.fromArray(leapHand.palmNormal).multiplyScalar(-1)

      # lookAt eye, target, up -> self position, target position, normal
      # of course, we just have a direction, and eye is used internall just to make a direction
      # z.subVectors( eye, target ).normalize();
      # so we hack in for now and set an eye of our direction and a target of 0,0,0
      # bone.update calls bone.updateMatrix calls matrix.compose(this.position, this.quaternion, this.scale)
      # matrixAutoUpdate must be false, in order for `updateMatrixWorld(force = true)` to be effective
      palm.matrix.lookAt(palm.worldDirection, zeroVector, palm.worldUp)
      palm.matrix.decompose(palm.position, palm.quaternion, palm.scale)
      palm.updateMatrixWorld(true)

      for leapFinger, i in leapHand.fingers
#        if i != 0
        if i == 1
#        if i == 0
          # wrist -> mcp -> pip -> dip -> tip

          palm.children[i].worldDirection.subVectors(leapFinger.pipPosition, leapFinger.mcpPosition).normalize()#.visualize()
          palm.children[i].mip.worldDirection.subVectors(leapFinger.dipPosition, leapFinger.pipPosition).normalize()#.visualize()
          palm.children[i].dip.worldDirection.subVectors(leapFinger.tipPosition, leapFinger.dipPosition).normalize()#.visualize()

        # we set this in to local space by comparing rotation axis against the local x axis.
          palm.children[i].positionFromWorld()
          palm.children[i].mip.positionFromWorld()
          palm.children[i].dip.positionFromWorld()

      palm.worldUp.visualize()
      palm.worldDirection.visualize()
#      indexFinger.worldUp.visualize()
#      indexFinger.worldDirection.visualize()
#      indexFinger.worldAxis.visualize()

#      if j == 0
#        console.log vec3().subVectors(indexFinger.children[0].children[0].position, indexFinger.children[0].position).length()

#      window.j++
#      window.j = window.j % 60
#      middleFinger.localAxis.x = 0.1
#      middleFinger.localAxis.z = -Math.abs(Math.cos(j/50))
#      middleFinger.localAxis.normalize()

      renderer.render(scene, camera)
