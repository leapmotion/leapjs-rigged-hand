JS Rigged Hand Plugin
==============

This allows a Leap-Enabled hand to be added to any Three.JS scene.
Requires LeapJS Skeletal 0.4.2 or greater with LeapJS-Plugins 0.1.3 or greater.

 - Live Demo: [http://leapmotion.github.io/leapjs-rigged-hand/](http://leapmotion.github.io/leapjs-rigged-hand/)
 - If you don't have a Leap, automatic mode is available.  Give it a moment to load and then make sure you have the page in focus for playback.  Insert your hand over the Leap to take control http://leapmotion.github.io/leapjs-rigged-hand/?playback=1

![hands](https://f.cloud.github.com/assets/407497/2405446/5e7ee120-aa50-11e3-8ac0-579b316efc04.png)

Automatically adds or removes hand meshes to/from the scene as they come in to or out of view of the leap controller.


## Usage:

### Basic

```coffeescript
# simplest possible usage, see `quickstart.html`
(window.controller = new Leap.Controller)
  .use('riggedHand')
  .connect()
```

This will create a canvas with fixed position which covers the entire screen.  A neat trick is to allow pointer-events to pass through the canvas with one CSS rule, so that you can interact with your page like normal.

```css
canvas{
  pointer-events: none;
}
```



### Advanced

```coffeescript
# advanced configuration, see `index.html` and `main.coffee`
(window.controller = new Leap.Controller)
  # handHold and handEntry are dependencies of this plugin, available to the controller through leap-plugins.js
  # By default rigged-hand will use these, but we can call explicitly to provide configuration:
  .use('handHold', {})
  .use('handEntry', {})
  .use('riggedHand', {
    parent: scene

    # this is called on every animationFrame 
    renderFn: ->
      renderer.render(scene, camera)
      # Here we update the camera controls for clicking and rotating
      controls.update()

    # These options are merged with the material options hash
    # Any valid Three.js material options are valid here.
    materialOptions: {
      wireframe: true,
      color: new THREE.Color(0xff0000)
    }
    geometryOptions: {}

    # This will show pink dots at the raw position of every leap joint.
    # they will be slightly offset from the rig shape, due to it having slightly different proportions.
    dotsMode: true

    # Sets the default position offset from the parent/scene. Default of new THREE.Vector3(0,-10,0)
    offset: new THREE.Vector3(0,0,0)

    # sets the scale of the mesh in the scene.  The default scale works with a camera of distance ~15.
    scale: 1.5

    # Allows hand movement to be scaled independently of hand size.
    # With a value of 2, the hand will cover twice the distance on screen as it does in the world.
    positionScale: 2

    # allows 2d text to be attached to joint positions on the screen
    # Labels are by default white text with a black dropshadow
    # this method is called for every bone on each frame
    # boneMeshes are named Finger_xx, where the first digit is the finger number, and the second the bone, 0 indexed.
    boneLabels: (boneMesh, leapHand)->
      return boneMesh.name

    # allows individual bones to be colorized
    # Here we turn thumb and index finger blue while pinching
    # this method is called for every bone on each frame
    # should return an object with hue, saturation, and an optional lightness ranging from 0 to 1
    # http://threejs.org/docs/#Reference/Math/Color [setHSL]
    boneColors: (boneMesh, leapHand)->
      if (boneMesh.name.indexOf('Finger_0') == 0) || (boneMesh.name.indexOf('Finger_1') == 0)
        return {
          hue: 0.6,
          saturation: leapHand.pinchStrength
        }

    # This will add a warning message to the page on browsers which do not support WebGL or do not have it enabled.
    # By default, this will be used unless a `parent` scene is passed in.
    # This uses @mrdoob's Detector.js
    # Chrome, Firefox, Safari Developer mode, and IE11 all support WebGL.  http://caniuse.com/webgl
    checkWebGL: true

  })
  .connect()
```

Note that the size of this file is quite large, as it includes left and right hand models.  It is recommended that you
include the files [from our CDN](https://developer.leapmotion.com/leapjs/plugins), as that will encourage browser caching
and ensure the assets are gzipped from 845KB to 348KB before sending.

### Scope objects

Certain objects are made available on the plugin scope.  This is the same "options" object which is passed in to `use`.

```coffeescript
scope = controller.plugins.riggedHand; 

scope.camera # THREE.js camera

scope.scene # THREE.js camera

scope.Detector # Can be used to detect webgl availability through `if !!Detector.webgl`
```

There are many which are currently undocumented.  Inspect the object manually to discover.

### Events

`riggedHand.meshAdded` and `riggedHand.meshRemoved` are available.  These may be useful to customize behaviors of the
hand or change defaults.  By default, `material.opacity == 0.7`, `material.depthTest == true`, and
`handMesh.castShadow == true`, but these could be customized in the event callback.

```javascript
controller.on('riggedHand.meshAdded', function(handMesh, leapHand){
  handMesh.material.opacity = 1;
});
```

### Scene Position

`handMesh.scenePosition(leapPosition, scenePosition)` can be used to convert coordinates from Leap Space to THREE scene space.
leapPosition should be an array [x,y,z] as found on Leap frames, scenePosition should be a `THREE.Vector3` which will be edited in-place.

[LIVE DEMO](http://leapmotion.github.io/leapjs-rigged-hand/?scenePosition=true)


```coffeescript
sphere = new THREE.Mesh(
  new THREE.SphereGeometry(1),
  new THREE.MeshBasicMaterial(0x0000ff)
)
scene.add(sphere)

controller.on 'frame', (frame)->
  if hand = frame.hands[0]
    handMesh = frame.hands[0].data('riggedHand.mesh')

    handMesh.scenePosition(hand.indexFinger.tipPosition, sphere.position)

```


### Screen Position

When a hand is on the screen, that hand will be available to your application (such as in a plugin or on 'frame' callback)
 through `frame.hands[index].data('riggedHand.mesh')`.  This will be the Three.js mesh, as is.

To get the css window coordinates of anything in leap-space, use the `handMesh.screenPosition` method, as seen in
main.coffee.  The number returned will be distance from the bottom left corner of the WebGL canvas.

Note that if a custom scene is passed in, `scope.renderer` must also be passed in/set.

```coffeescript
controller.on 'frame', (frame)->
  if hand = frame.hands[0]
    handMesh = frame.hands[0].data('riggedHand.mesh')
    # to use screenPosition, we pass in any leap vector3 and the camera
    screenPosition = handMesh.screenPosition(
      hand.fingers[1].tipPosition
    )
    cursor.style.left = screenPosition.x
    cursor.style.bottom = screenPosition.y
```



Contributing
===============

#### Open an issue!
 - https://github.com/leapmotion/leapjs-plugins/issues
 - We listen for bug reports, feature requests, contributions, an so on :-)
