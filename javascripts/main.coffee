HEIGHT = window.innerHeight
WIDTH = window.innerWidth

renderer = new THREE.WebGLRenderer( alpha: true )
#renderer.setClearColor( 0x000000, 0)
renderer.setClearColor( 0x000000, 1)
renderer.setSize(WIDTH, HEIGHT)
document.getElementById('threejs').appendChild(renderer.domElement)


camera = new THREE.PerspectiveCamera(
  90,
  WIDTH / HEIGHT,
  10,
  1000
)

camera.position.z = 30
camera.position.x = 10
camera.position.y = 10
camera.lookAt(new THREE.Vector3(0,0,0))

scene = new THREE.Scene()
scene.add(camera)

scene.add new THREE.AxisHelper(50)


scene.add new THREE.AmbientLight( 0x222222)
directionalLight = new THREE.DirectionalLight(  0xffffff, 0.5 )
directionalLight.position.set( 0, 1, 1000 );
scene.add( directionalLight );

pointLight = new THREE.PointLight(0xFFffff)
pointLight.position =  new THREE.Vector3(20,20,10)
pointLight.lookAt new THREE.Vector3(0,0,10)
scene.add(pointLight)

rectangle = new THREE.Mesh(
  new THREE.CubeGeometry(
    4, 1, 8),
  new THREE.MeshPhongMaterial({
      color: 0x00ff00
    })
  )
rectangle.position = new THREE.Vector3(0,0,0)
scene.add(rectangle)


sphere = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshPhongMaterial({
      color: 0xff0000
    })
)
sphere.position = new THREE.Vector3(10,10,0)
scene.add(sphere)

animation = undefined
handMesh = undefined



#(new THREE.JSONLoader).load 'javascripts/blender-export-from-collada-from-maya.json',  (geometryWithBones) ->
#(new THREE.SceneLoader).load 'javascripts/right-hand-via-fbx-py-converter.json',  (object) ->
# JSONLoader expects vertices
# ObjectLoader seems to load empty objects for materials and geometries, tries to act on json.object rather than json.objects
(new THREE.SceneLoader).load 'javascripts/right-hand-via-fbx-py-converter.json',  (object) ->
#    geometry.faces = object.geometries.Geometry_64_g0_01.faces
#    geometry.vertices = object.geometries.Geometry_64_g0_01.vertices
#    console.log 'loaded', geometry
    geometry = object.geometries.Geometry_64_g0_01
#    geometry.bones = object.bones

    # it appears that all the bones belong to a geometry in a flat structure, but have links to set nesting.
    # it looks like the parent must be added to the array before the child.
    geometry.bones = []

    # currently puts all bones in a line. :-/ this should be enought to test some motion.
    updateBoneAttrs = (boneAttrs, parent)->
      console.log "udpate attrs (inner)", boneAttrs.name
      boneAttrs.pos = [boneAttrs.position.x, boneAttrs.position.y, boneAttrs.position.z]
      q = (new THREE.Quaternion).setFromEuler(new THREE.Euler(boneAttrs.rotation[0], boneAttrs.rotation[1], boneAttrs.rotation[2], 'XYZ'))
      boneAttrs.rotq = [q._x, q._y, q._z, q._w]
      boneAttrs.scl = [boneAttrs.scale.x, boneAttrs.scale.y, boneAttrs.scale.z]
      boneAttrs.parent = parent

      geometry.bones.push boneAttrs
      myIndex = geometry.bones.length - 1
      for childBoneAttrs in boneAttrs.children
        updateBoneAttrs(childBoneAttrs, myIndex)

    updateBoneAttrs(object.objects['Bip01 R Hand'], -1)






    THREE.GeometryUtils.center(geometry)
#    object.materials.phong1.skinning = true
    handMesh = new THREE.SkinnedMesh( geometry, object.materials.phong1)
    handMesh.useVertexTexture = false
    handMesh.scale = new THREE.Vector3(0.01,0.01,0.01)

    someBone = handMesh.children[0].children[0].children[0]
    someBone.position.multiply(new THREE.Vector3(20,20,20))
    handMesh.children[0].update(handMesh.matrix, true)
    handMesh.children[0].children[0].children[0].rotation

#    handMesh.material.skinning = true

    # First we apply a base transform, to make the hand oriented how we want it:
    baseQuaternion = (new THREE.Quaternion).setFromEuler(new THREE.Euler(-Math.PI / 2, 0, -Math.PI / 2 , 'XYZ'))
    handMesh.quaternion = baseQuaternion
    scene.add handMesh


    Leap.loop (frame)->
      if leapHand = frame.hands[0]
        handMesh.position.x = leapHand.stabilizedPalmPosition[0] / 10
        handMesh.position.y = leapHand.stabilizedPalmPosition[1] / 10
        handMesh.position.z = leapHand.stabilizedPalmPosition[2] / 10

        handMesh.quaternion = baseQuaternion.clone().multiply((new THREE.Quaternion).setFromEuler(
          new THREE.Euler(leapHand.roll(), leapHand.direction[1], -leapHand.direction[0], 'XYZ' )
        ))

#        handMesh.bones[0].rotateX(Math.PI / 2).rotateY(Math.PI / 2)
#        handMesh.bones[1].rotateX(Math.PI / 2).rotateY(Math.PI / 2)
#        handMesh.bones[2].rotateX(Math.PI / 2).rotateY(Math.PI / 2)
#        for bone in handMesh.bones
#          bone.rotation.set(0.5,0.5,0.5)
#        object.objects["Bip01 R Hand"].rotateX(Math.PI / 2).rotateY(Math.PI / 2)
#        object.objects["Bip01 R Finger3"].rotateX(Math.PI / 2).rotateY(Math.PI / 2)
#        object.objects["Bip01 R Finger32"].rotateX(Math.PI / 2).rotateY(Math.PI / 2)

      renderer.render(scene, camera)
