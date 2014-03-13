JS Rigged Hand Plugin
==============

This allows a Leap-Enabled hand to be added to any Three.JS scene.
Requires LeapJS Skeletal 0.4.2 or greater with LeapJS-Plugins 0.1.3 or greater.

 - Live Demo: [http://leapmotion.github.io/rigged-hand/](http://leapmotion.github.io/rigged-hand/)
 - If you don't have a Leap, automatic mode is available.  Ths JSON frame stream is almost 4mb, so give it a moment to load
 and then make sure you have the page in focus for playback. http://leapmotion.github.io/rigged-hand/?spy=1

![hands](https://f.cloud.github.com/assets/407497/2405446/5e7ee120-aa50-11e3-8ac0-579b316efc04.png)

Automatically adds or removes hand meshes to/from the scene as they come in to or out of view of the leap controller.


## Usage:

(See `Main.coffee` or `main.js`)

```coffeescript
# simplest possible usage
(new Leap.Controller)
  # handHold and handEntry are dependencies of this plugin, which must be "used" before the riggedHand plugin.
  # They are available to the controller through leap-plugins-0.4.3.js
  .use('handHold')
  .use('handEntry')
  .use('riggedHand', {
    # this is the Three Object3d which the hands will be added to
    parent: myScene
    # this method, if provided, will be called on every leap animationFrame.
    # If not provided, the hand data will still be updated in the scene, but the scene not re-rendered.
    renderFn: ->
      myRenderer.render(myScene, myCamera)
  })
  .connect()
```

```coffeescript
# with options
(new Leap.Controller)
  .use('handHold')
  .use('handEntry')
  .use('riggedHand', {
    parent: scene
    renderFn: ->
      renderer.render(scene, camera)
      # Here we update the camera controls for clicking and rotating
      controls.update()
    # These options are merged with the material options hash
    # Any valid Three.js material options are valid here.
    materialOptions: {
      wireframe: true
    }
    geometryOptions: {}
    # This will show pink dots at the raw position of every leap joint.
    # they will be slightly offset from the rig shape, due to it having slightly different proportions.
    dotsMode: true
  })
  .connect()
```


## TODO:

WIP Two more options: scale and offset. These would allow proper customization of the rigged hand within the scene.