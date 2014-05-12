# todo: document that this must be run via http server
# Options include:
# parent - Optional - A ThreeJS.Object3d, such as a scene or camera, which the hands will be added to
# offset - ThreeJS.Vector3, a constant offset between the parent and the hands.  Default is new THREE.Vector3(0,-10,0)
# scale - An integer, sizing the rigged hand relative to your scene.  Default is 1
# renderFn - If provided, this will be executed on every animation frame.
#            E.g. function(){ renderer.render(scene, camera) }
# materialOptions - A hash of properties for the material, such as wireframe: true
# meshOptions - A hash of properties for the hand meshes, such as castShadow: true
# dotsMode - shows a dot for every actual joint position, for comparison against the mesh calculations
# checkWebGL: Boolean - whether or not to display a warning for non webgl-capable browser.  By default, this
# renderer: a THREE.js renderer to use.  By default, one will be created to fill the entire window, and be automatically
#     resized.  Passing in a custom renderer will cause camera.aspect and camera.setSize to no longer be set.
#
# will be used only if a THREE.js scene is not passed in for the hand.

`
// underscore's _.each implementation, use for _.extend
var _each = function(obj, iterator, context) {
    if (obj == null) return obj;
    if (Array.prototype.forEach && obj.forEach === Array.prototype.forEach) {
      obj.forEach(iterator, context);
    } else if (obj.length === +obj.length) {
      for (var i = 0, length = obj.length; i < length; i++) {
        if (iterator.call(context, obj[i], i, obj) === breaker) return;
      }
    } else {
      var keys = _.keys(obj);
      for (var i = 0, length = keys.length; i < length; i++) {
        if (iterator.call(context, obj[keys[i]], keys[i], obj) === breaker) return;
      }
    }
    return obj;
  };

// underscore's _.extend implementation
var _extend = function (obj) {
  _each(Array.prototype.slice.call(arguments, 1), function(source) {
    if (source) {
      for (var prop in source) {
        obj[prop] = source[prop];
      }
    }
  });
  return obj;
}

// underscore's _.sortBy implementation
var _isFunction = function(obj) {
  return typeof obj === 'function';
};

var lookupIterator = function(value) {
  if (value == null) return _.identity;
  if (_isFunction(value)) return value;
  return _.property(value);
};

_map = function(obj, iterator, context) {
  var results = [];
  if (obj == null) return results;
  if (Array.prototype.map && obj.map === Array.prototype.map) return obj.map(iterator, context);
  each(obj, function(value, index, list) {
    results.push(iterator.call(context, value, index, list));
  });
  return results;
};

_pluck = function(obj, key) {
  return _map(obj, _property(key));
};

_property = function(key) {
  return function(obj) {
    return obj[key];
  };
};

var _sortBy = function (obj, iterator, context) {
  iterator = lookupIterator(iterator);
  return _pluck(_map(obj, function(value, index, list) {
    return {
      value: value,
      index: index,
      criteria: iterator.call(context, value, index, list)
    };
  }).sort(function(left, right) {
    var a = left.criteria;
    var b = right.criteria;
    if (a !== b) {
      if (a > b || a === void 0) return 1;
      if (a < b || b === void 0) return -1;
    }
    return left.index - right.index;
  }), 'value');
}`

# http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
unless THREE.Quaternion.prototype.setFromVectors
  THREE.Quaternion.prototype.setFromVectors = (a, b)->
    axis = (new THREE.Vector3).crossVectors(a, b)
    @set(axis.x, axis.y, axis.z, 1 + a.dot(b))
    @normalize()
    @

unless THREE.Bone.prototype.positionFromWorld

  # Set's the bones quaternion
  THREE.Bone.prototype.positionFromWorld = (eye, target) ->
    directionDotParentDirection = @worldDirection.dot(@parent.worldDirection)
    angle = Math.acos directionDotParentDirection
    @worldAxis.crossVectors(@parent.worldDirection, @worldDirection).normalize()

    # http://en.wikipedia.org/wiki/Rodrigues'_rotation_formula
    # v = palmNormal = parentUp
    # k = rotation axis = worldAxis
    @worldUp.set(0,0,0)
      .add(@parent.worldUp.clone().multiplyScalar(directionDotParentDirection))
      .add((new THREE.Vector3).crossVectors(@worldAxis, @parent.worldUp).multiplyScalar(Math.sin(angle)))
      .add(@worldAxis.clone().multiplyScalar(@worldAxis.dot(@parent.worldUp) * (1 - directionDotParentDirection)))
      .normalize()


    @matrix.lookAt(eye, target, @worldUp)
    @worldQuaternion.setFromRotationMatrix( @matrix )
    # Set this quaternion to be only the local change:
    @quaternion.copy(@parent.worldQuaternion).inverse().multiply(@worldQuaternion)
    @

# Creates the default ThreeJS scene if no parent passed in.
initScene = (element)->
  scope = @
  @scene = new THREE.Scene()

  @scene.add new THREE.AmbientLight(0x888888)

  pointLight = new THREE.PointLight(0xFFffff)
  pointLight.position = new THREE.Vector3(-20, 10, 0)
  pointLight.lookAt new THREE.Vector3(0, 0, 0)
  @scene.add(pointLight)

  @camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    1,
    1000
  )
  @camera.position.fromArray([0,6,30])
  @camera.lookAt(new THREE.Vector3(0, 0, 0))

  unless @renderer
    @renderer = new THREE.WebGLRenderer(alpha: true)
    @renderer.setClearColor( 0x000000, 0 )
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.domElement.style.position = 'fixed'
    @renderer.domElement.style.top = 0
    @renderer.domElement.style.left = 0
    @renderer.domElement.style.width = '100%'
    @renderer.domElement.style.height = '100%'
    element.appendChild(@renderer.domElement)

    window.addEventListener( 'resize', ->
      scope.camera.aspect = window.innerWidth / window.innerHeight
      scope.camera.updateProjectionMatrix()

      scope.renderer.setSize( window.innerWidth, window.innerHeight )

      scope.renderer.render(scope.scene, scope.camera)
    , false )

  scope.scene.add(scope.camera)
  scope.renderer.render(scope.scene, scope.camera)



Leap.plugin 'riggedHand', (scope = {})->
  @use('handHold')
  @use('handEntry')
  @use('versionCheck', {requiredProtocolVersion: 6})

  scope.offset ||= new THREE.Vector3(0,-10,0)
  scope.scale ||= 1
  # this allow the hand to move disproportionately to its size.
  scope.positionScale ||= 1
  scope.initScene = initScene

  controller = this


  # check WebGL support:
  scope.Detector = Detector

  if scope['checkWebGL'] == undefined
    scope.checkWebGL = !scope.parent

  if scope.checkWebGL
    unless scope.Detector.webgl
      scope.Detector.addGetWebGLMessage();
      return


  unless scope.parent
    scope.initScene(document.body)
    scope.parent = scope.scene

  scope.renderFn ||= ->
    scope.renderer.render(scope.scene, scope.camera)


  projector = new THREE.Projector()

  spareMeshes = {
    left: [],
    right: []
  }

  # converts a ThreeJS JSON blob in to a mesh
  createMesh = (JSON)->
    # note: this causes a good 90ms pause on first run
    # it appears as if mesh.clone does not clone material and geometry, so at this point we refrain from doing so
    # see THREE.SkinnedMesh.prototype.clone
    # instead, we call createMesh right off, to have the results "cached"
    data = (new THREE.JSONLoader).parse JSON
    data.materials[0].skinning = true
    data.materials[0].transparent = true
    data.materials[0].opacity = 0.7
    data.materials[0].emissive.setHex(0x888888)

    data.materials[0].vertexColors = THREE.VertexColors
    data.materials[0].vertexColors = THREE.NoColors;
    data.materials[0].depthTest = true

#    		"#if defined( USE_MAP ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( USE_SPECULARMAP )",
    m = data.materials[0]
    console.log(m.map, m.lightMap, m.specularMap, m.envMap)
#    debugger


#    material = new THREE.ShaderMaterial({
#       uniforms: uniforms,
#       vertexShader: document.getElementById('vertexShader').innerHTML,
#       fragmentShader: document.getElementById('fragmentShader').innerHTML
#    });

#    material = new THREE.MeshLambertMaterial
#    material.skinning = true


    _extend(data.materials[0], scope.materialOptions)
    _extend(data.geometry,     scope.geometryOptions)

    handMesh = new THREE.SkinnedMesh(data.geometry, data.materials[0])

    handMesh.scale.multiplyScalar(scope.scale)
    handMesh.positionRaw = new THREE.Vector3
    handMesh.fingers = handMesh.children[0].children
    handMesh.castShadow = true

    # Re-create the skin index on bones in a manner which will be accessible later
    handMesh.bonesBySkinIndex = {}
    i = 0
    handMesh.children[0].traverse (bone)->
      bone.skinIndex = i
      handMesh.bonesBySkinIndex[i] = bone
      i++

    handMesh.boneLabels = {}

    if scope.boneLabels
      handMesh.traverse (bone)->
        label = handMesh.boneLabels[bone.id] ||= document.createElement('div')
        label.style.position = 'absolute'
        label.style.zIndex = '10'

        label.style.color = 'white'
        label.style.fontSize = '20px'
        label.style.textShadow = '0px 0px 3px black'
        label.style.fontFamily = 'helvetica'
        label.style.textAlign = 'center'

        for attribute, value of scope.labelAttributes
          label.setAttribute(attribute, value)


    # takes in a vec3 of leap coordinates, and converts them in to screen position,
    # based on the hand mesh position and camera position.
    handMesh.screenPosition = (position, camera)->
      console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera);
      screenPosition = (new THREE.Vector3())

      if position instanceof THREE.Vector3
        screenPosition.fromLeap(position.toArray(), @leapScale)
      else
        screenPosition.fromLeap(position, @leapScale)
          # the palm may have its base position scaled on top of leap coordinates:
          .sub(@positionRaw)
          .add(@position)

      screenPosition = projector.projectVector(screenPosition, camera)
      screenPosition.x = (screenPosition.x * window.innerWidth / 2) + window.innerWidth / 2
      screenPosition.y = (screenPosition.y * window.innerHeight / 2) + window.innerHeight / 2
      screenPosition

    handMesh.scenePosition = (leapPosition, scenePosition, offset) ->
      scenePosition.fromLeap(leapPosition, handMesh.leapScale, offset)
        # these two add the base offset
        .sub(handMesh.positionRaw)
        .add(handMesh.position)

    handMesh

  getMesh = (leapHand)->
    # Meshes are kept in memory after first-use, as it takes about 24ms, or two frames, to add one to the screen
    # on a good computer.
    meshes = spareMeshes[leapHand.type]
    if meshes.length > 0
      handMesh = meshes.pop()
    else
      JSON = rigs[leapHand.type]
      handMesh = createMesh(JSON)

    handMesh



  # initialize JSONloader for speed
  createMesh(rigs['right'])

  unless THREE.Vector3.prototype.fromLeap
    # converts a leap array [x,y,z] in to a scene-based vector3.
    THREE.Vector3.prototype.fromLeap = (array, scale, offset)->
      @fromArray(array).divideScalar(scale).add(offset || scope.offset)

  zeroVector = new THREE.Vector3(0,0,0)
  
  addMesh = (leapHand)->
    console.time 'addMesh'

    handMesh = getMesh(leapHand)

    scope.parent.add handMesh
    leapHand.data('riggedHand.mesh', handMesh)
    palm = handMesh.children[0]

    # Mesh scale set by comparing leap first bone length to mesh first bone length
    handMesh.leapScale =
      (new THREE.Vector3).subVectors(
        (new THREE.Vector3).fromArray(leapHand.fingers[2].pipPosition)
        (new THREE.Vector3).fromArray(leapHand.fingers[2].mcpPosition)
      ).length() / handMesh.fingers[2].position.length() / scope.scale

    # Initialize Vectors for later use
    # actually we need the above so that position is factored in
    palm.worldUp = new THREE.Vector3
    palm.positionLeap = new THREE.Vector3
    for rigFinger in handMesh.fingers
      rigFinger.pip = rigFinger.children[0]
      rigFinger.dip = rigFinger.pip.children[0]
      rigFinger.tip = rigFinger.dip.children[0]

      rigFinger.    worldQuaternion = new THREE.Quaternion
      rigFinger.pip.worldQuaternion = new THREE.Quaternion
      rigFinger.dip.worldQuaternion = new THREE.Quaternion

      rigFinger.    worldAxis       = new THREE.Vector3
      rigFinger.pip.worldAxis       = new THREE.Vector3
      rigFinger.dip.worldAxis       = new THREE.Vector3

      rigFinger.    worldDirection  = new THREE.Vector3
      rigFinger.pip.worldDirection  = new THREE.Vector3
      rigFinger.dip.worldDirection  = new THREE.Vector3

      rigFinger.    worldUp         = new THREE.Vector3
      rigFinger.pip.worldUp         = new THREE.Vector3
      rigFinger.dip.worldUp         = new THREE.Vector3

      rigFinger.    positionLeap   = new THREE.Vector3
      rigFinger.pip.positionLeap   = new THREE.Vector3
      rigFinger.dip.positionLeap   = new THREE.Vector3
      rigFinger.tip.positionLeap   = new THREE.Vector3

    palm.worldDirection  = new THREE.Vector3
    palm.worldQuaternion = handMesh.quaternion


    if scope.boneLabels
      # start with palm
      handMesh.children[0].traverse (bone)->
        document.body.appendChild handMesh.boneLabels[bone.id]

    controller.emit('riggedHand.meshAdded', handMesh, leapHand)

    console.timeEnd 'addMesh'


  removeMesh = (leapHand)->
    handMesh = leapHand.data('riggedHand.mesh')
    leapHand.data('riggedHand.mesh', null)

    scope.parent.remove handMesh

    spareMeshes[leapHand.type].push(handMesh)

    if scope.boneLabels
      # start with palm
      handMesh.children[0].traverse (bone)->
        document.body.removeChild handMesh.boneLabels[bone.id]

    controller.emit('riggedHand.meshRemoved', handMesh, leapHand)
    scope.renderFn() if scope.renderFn

  # for use when dotsMode = true
  dots = {}
  basicDotMesh = new THREE.Mesh(
    new THREE.IcosahedronGeometry( .3 , 1 ),
    new THREE.MeshNormalMaterial()
  )
  
  scope.positionDots = (leapHand, handMesh, offset)->
    return unless scope.dotsMode

    for leapFinger, i in leapHand.fingers
      for point in ['mcp', 'pip', 'dip', 'tip']
        unless dots["#{point}-#{i}"]
          dots["#{point}-#{i}"] = basicDotMesh.clone()
          scope.parent.add dots["#{point}-#{i}"]

        handMesh.scenePosition(leapFinger["#{point}Position"], dots["#{point}-#{i}"].position, offset)

  @on 'handFound', addMesh
  @on 'handLost',  removeMesh



  {
    frame: (frame)->
      scope.stats.begin() if scope.stats
      for leapHand in frame.hands
        # this works around a subtle bug where non-extended fingers would appear after extended ones
        leapHand.fingers = _sortBy(leapHand.fingers, (finger)-> finger.id)
        handMesh = leapHand.data('riggedHand.mesh')
        palm = handMesh.children[0]

        palm.positionLeap.fromArray(leapHand.palmPosition)
        # wrist -> mcp -> pip -> dip -> tip
        for mcp, i in palm.children
          mcp.    positionLeap.fromArray(leapHand.fingers[i].mcpPosition)
          mcp.pip.positionLeap.fromArray(leapHand.fingers[i].pipPosition)
          mcp.dip.positionLeap.fromArray(leapHand.fingers[i].dipPosition)
          mcp.tip.positionLeap.fromArray(leapHand.fingers[i].tipPosition)


        # set heading on palm so that finger.parent can access
        palm.worldDirection.fromArray(leapHand.direction)
        palm.up.fromArray(leapHand.palmNormal).multiplyScalar(-1)
        palm.worldUp.fromArray(leapHand.palmNormal).multiplyScalar(-1)

        # position mesh to palm
        offset = if (typeof scope.offset == 'function') then scope.offset(leapHand) else scope.offset

        handMesh.positionRaw.fromLeap(leapHand.palmPosition, handMesh.leapScale, offset)
        handMesh.position.copy(handMesh.positionRaw).multiplyScalar(scope.positionScale)

        handMesh.matrix.lookAt(palm.worldDirection, zeroVector, palm.up)

        # set worldQuaternion before using it to position fingers (threejs updates handMesh.quaternion, but only too late)
        palm.worldQuaternion.setFromRotationMatrix( handMesh.matrix )

        for mcp in palm.children
          mcp.traverse (bone)->
            if bone.children[0]
              bone.worldDirection.subVectors(bone.children[0].positionLeap, bone.positionLeap).normalize()
              bone.positionFromWorld(bone.children[0].positionLeap, bone.positionLeap)

        scope.positionDots(leapHand, handMesh, offset)


        if scope.boneLabels
          palm.traverse (bone)->
            # the condition here is necessary in case scope.boneLabels is set while a hand is in the frame
            if element = handMesh.boneLabels[bone.id]
              screenPosition = handMesh.screenPosition(bone.positionLeap, scope.camera)
              element.style.left = "#{screenPosition.x}px"
              element.style.bottom = "#{screenPosition.y}px"
              element.innerHTML = scope.boneLabels(bone, leapHand) || ''

        if scope.boneColors
          geometry = handMesh.geometry
          # H.  S controlled by weights, Lightness constant.
          boneColors = {}

          i = 0
          while i < geometry.vertices.length
            # 0-index at palm id
            # boneColors must return an array with [hue, saturation, lightness]
            boneColors[geometry.skinIndices[i].x] ||= (scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].x], leapHand) || {hue: 0, saturation: 0})
            boneColors[geometry.skinIndices[i].y] ||= (scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].y], leapHand) || {hue: 0, saturation: 0})
            xBoneHSL = boneColors[geometry.skinIndices[i].x]
            yBoneHSL = boneColors[geometry.skinIndices[i].y]
            weights = geometry.skinWeights[i]

            # the best way to do this would be additive blending of hue based upon weights
            # currently, we just hue to whichever is set
            hue = xBoneHSL.hue || yBoneHSL.hue
            lightness = xBoneHSL.lightness || yBoneHSL.lightness || 0.5

            saturation =
              (xBoneHSL.saturation) * weights.x +
              (yBoneHSL.saturation) * weights.y


            geometry.colors[i] ||= new THREE.Color()
            geometry.colors[i].setHSL(hue, saturation, lightness)
            i++
          geometry.colorsNeedUpdate = true

          # copy vertex colors to the face
          faceIndices = 'abc'
          for face in geometry.faces
            j = 0
            while j < 3
              face.vertexColors[j] = geometry.colors[face[faceIndices[j]]]
              j++


      scope.renderFn() if scope.renderFn
      scope.stats.end() if scope.stats
  }