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


(new THREE.SceneLoader).load 'javascripts/right-hand.json',  (object) ->
  console.log 'loaded', object
  geometry = object.geometries.Geometry_64_g0_01
  THREE.GeometryUtils.center(geometry)
  handMesh = new THREE.SkinnedMesh( geometry, object.materials.phong1)
  handMesh.useVertexTexture = false
  handMesh.scale = new THREE.Vector3(0.01,0.01,0.01)

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

    renderer.render(scene, camera)
