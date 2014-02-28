HEIGHT = window.innerHeight
WIDTH = window.innerWidth
scene = new THREE.Scene()

renderer = new THREE.WebGLRenderer(alpha: true)
#renderer.setClearColor( 0x000000, 0) # for overlay on page
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
cameraPosition = 'front'
renderer.domElement.onclick = ->
  camera.position.fromArray(cameraPositions[cameraPosition])
  camera.lookAt(new THREE.Vector3(0, 0, 0))
  if cameraPosition == 'front' then cameraPosition = 'back' else cameraPosition = 'front'
  renderer.render(scene, camera)
renderer.domElement.click()

scene.add(camera)



THREE.Bone.prototype.positionFromWorld = (eye, target) ->
  @matrix.lookAt(eye, target, @up)
  @worldQuaternion.setFromRotationMatrix( @matrix )
  # Set this quaternion to be only the local change:
  @quaternion.copy(@parent.worldQuaternion).inverse().multiply(@worldQuaternion)
  @


THREE.Vector3.prototype.fromLeap = (array, scale)->
  @fromArray(array).divideScalar(scale)
  @y -= 5

showRawPositions = true


(new THREE.JSONLoader).load 'javascripts/27left.json', (geometryWithBones, materials) ->
  material = materials[0]
  material.skinning = true
  material.wireframe = true

  window.handMesh = new THREE.SkinnedMesh(
    geometryWithBones, material
  )
  handMesh.castShadow = true
  handMesh.receiveShadow = true

  scene.add handMesh

  window.palm = handMesh.children[0]
  # actually we need the above so that position is factored in
  palm.matrixWorld = handMesh.matrix


  # initialize
  for rigFinger in palm.children
    rigFinger.mip = rigFinger.children[0]
    rigFinger.dip = rigFinger.children[0].children[0]

    rigFinger.worldQuaternion =     new THREE.Quaternion
    rigFinger.mip.worldQuaternion = new THREE.Quaternion
    rigFinger.dip.worldQuaternion = new THREE.Quaternion

  palm.worldDirection  = new THREE.Vector3
  palm.worldQuaternion = handMesh.quaternion

  dots = {}
  basicDotMesh = new THREE.Mesh(
    new THREE.IcosahedronGeometry( .3 , 1 ) ,
    new THREE.MeshNormalMaterial()
  )

  renderer.render(scene, camera)

  scale = undefined

  Leap.loop (frame)->
    if (leapHand = frame.hands[0]) && leapHand.type == 'left'
      unless scale
        scale ||= vec3().subVectors(leapHand.fingers[2].pipPosition3, leapHand.fingers[2].mcpPosition3).length() / palm.children[2].position.length()

      palm.worldDirection.fromArray(leapHand.direction)
      palm.up.fromArray(leapHand.palmNormal).multiplyScalar(-1)

      handMesh.position.fromLeap(leapHand.stabilizedPalmPosition, scale)
      handMesh.matrix.lookAt(palm.worldDirection, zeroVector, palm.up)
      # set worldQuaternion before using it to position fingers (threejs updates handMesh.quaternion, but only too late)
      palm.worldQuaternion.setFromRotationMatrix( handMesh.matrix )

      for leapFinger, i in leapHand.fingers
        # wrist -> mcp -> pip -> dip -> tip
        palm.children[i].positionFromWorld(leapFinger.pipPosition3, leapFinger.mcpPosition3)
        palm.children[i].mip.positionFromWorld(leapFinger.dipPosition3, leapFinger.pipPosition3)
        palm.children[i].dip.positionFromWorld(leapFinger.tipPosition3, leapFinger.dipPosition3)

        if showRawPositions
          for point in ['mcp', 'pip', 'dip', 'tip']
            unless dots["#{point}-#{i}"]
              dots["#{point}-#{i}"] = basicDotMesh.clone()
              scene.add dots["#{point}-#{i}"]

            dots["#{point}-#{i}"].position.fromLeap(leapFinger["#{point}Position"], scale)


      renderer.render(scene, camera)
