initScene = (element)->
  HEIGHT = window.innerHeight
  WIDTH = window.innerWidth
  window.scene = new THREE.Scene()

  window.renderer = new THREE.WebGLRenderer(alpha: true)
  #renderer.setClearColor( 0x000000, 0) # for overlay on page
  renderer.setClearColor(0x000000, 1)
  renderer.setSize(WIDTH, HEIGHT)
  element.appendChild(renderer.domElement)

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

  camera.position.fromArray([0,3,15])
  camera.lookAt(new THREE.Vector3(0, 0, 0))
  window.controls = new THREE.TrackballControls( camera )
  scene.add(camera)

  renderer.render(scene, camera)


initScene(document.body)

(new Leap.Controller)
  .use('handHold')
  .use('handEntry')
  .use('riggedHand', {
    parent: scene
    renderFn: ()->
      renderer.render(scene, camera)
      controls.update()
  })
  .connect()

