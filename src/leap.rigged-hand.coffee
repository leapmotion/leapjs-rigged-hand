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

TO_RAD = Math.PI / 180

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


  geometry = new THREE.SphereGeometry( 0.3, 32, 32 );
  material = new THREE.MeshBasicMaterial( {color: 0xff0000} );
  window.sphere = new THREE.Mesh( geometry, material );
  @scene.add( window.sphere );

  window.sphere = new THREE.SphereGeometry(10)
  @scene.add(sphere)

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
#  scope.offset ||= new THREE.Vector3(0,-84,0)
  scope.scale ||= 1
  # this allow the hand to move disproportionately to its size.
  scope.positionScale ||= 0.4
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
  # this should be converted to a subclass of SkinnedMesh which still responds to isntanceof SkinnedMesh
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
    data.materials[0].depthTest = true

    _extend(data.materials[0], scope.materialOptions)
    _extend(data.geometry,     scope.geometryOptions)
    handMesh = new THREE.SkinnedMesh(data.geometry, data.materials[0])
    handMesh.scale.multiplyScalar(scope.scale * 50)
    handMesh.castShadow = true
    handMesh.positionRaw = new THREE.Vector3

    handMesh.palm = handMesh.children[0].children[0].children[0]
    handMesh.fingers = handMesh.palm.children

    thumb = handMesh.fingers.splice(1,1)
    handMesh.fingers.unshift(thumb)
    console.log "Mesh fingers:", handMesh.fingers.map( (finger)-> finger.name )



    # our besh has a weird "root" bone, which offsets the rotations unless we axe it
    # this should be removed in future versions of the mesh
    handMesh.children[0].children[0].position = new THREE.Vector3(0,0,0)

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
    # accepts optional width and height values, which default to
    handMesh.screenPosition = (position)->

      camera = scope.camera
      console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera);

      width = scope.renderer.domElement.width
      height = scope.renderer.domElement.height
      console.assert(width && height);

      screenPosition = (new THREE.Vector3())

      if position instanceof THREE.Vector3
        screenPosition.fromLeap(position.toArray(), @leapScale)
      else
        screenPosition.fromLeap(position, @leapScale)
          # the palm may have its base position scaled on top of leap coordinates:
          .sub(@positionRaw)
          .add(@position)

      screenPosition = projector.projectVector(screenPosition, camera)
      screenPosition.x = (screenPosition.x * width / 2) + width / 2
      screenPosition.y = (screenPosition.y * height / 2) + height / 2

      console.assert(!isNaN(screenPosition.x) && !isNaN(screenPosition.x), 'x/y screen position invalid')

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

  mesh = createMesh(rigs['left'])

  window.fatArrow = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0x000000, 0.5, 0.5)
  fatArrow.position = mesh.position
  scope.scene.add(window.fatArrow)

  window.fatArrow2 = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0x000000, 0.5, 0.5)
  fatArrow2.position = mesh.position
  scope.scene.add(window.fatArrow2)

  window.fatArrow3 = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0xff0000, 0.5, 0.5)
  fatArrow3.position = mesh.position
  scope.scene.add(window.fatArrow3)

  window.arrow = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0x000000)
  arrow.position = mesh.position
  scope.scene.add(window.arrow)

  window.arrow2 = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0x660000)
  arrow2.position = mesh.position
  scope.scene.add(window.arrow2)

  window.arrow3 = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0xff6600)
  arrow3.position = mesh.position
  scope.scene.add(window.arrow3)

  window.arrow4 = new THREE.ArrowHelper(new THREE.Vector3( 0, 0, 0 ), new THREE.Vector3( 1, 0, 0 ), 4, 0x0000ff)
  arrow4.position = mesh.position
  scope.scene.add(window.arrow4)


#  scope.scene.add(mesh)
  sphere.position = mesh.position
  window.camera = scope.camera


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
    palm = handMesh.palm

    # Mesh scale set by comparing leap first bone length to mesh first bone length
    handMesh.leapScale =
      (new THREE.Vector3).subVectors(
        (new THREE.Vector3).fromArray(leapHand.fingers[2].pipPosition),
        (new THREE.Vector3).fromArray(leapHand.fingers[2].mcpPosition)
      ).length() / handMesh.fingers[2].position.length() / scope.scale



    # Initialize Vectors for later use
    # actually we need the above so that position is factored in
    palm.worldUp = new THREE.Vector3
    palm.positionLeap = new THREE.Vector3

    for rigFinger, i in handMesh.fingers

      # thumb is index 1 and has one less bone
      if i == 1
        rigFinger.mcp = rigFinger
      else
        rigFinger.mcp = rigFinger.children[0]

      rigFinger.pip = rigFinger.mcp.children[0]
      rigFinger.dip = rigFinger.pip.children[0]
      rigFinger.tip = rigFinger.dip.children[0]

      rigFinger.    worldQuaternion = new THREE.Quaternion
      rigFinger.mcp.worldQuaternion = new THREE.Quaternion
      rigFinger.pip.worldQuaternion = new THREE.Quaternion
      rigFinger.dip.worldQuaternion = new THREE.Quaternion

      rigFinger.    worldAxis       = new THREE.Vector3
      rigFinger.mcp.worldAxis       = new THREE.Vector3
      rigFinger.pip.worldAxis       = new THREE.Vector3
      rigFinger.dip.worldAxis       = new THREE.Vector3

      rigFinger.    worldDirection  = new THREE.Vector3
      rigFinger.mcp.worldDirection  = new THREE.Vector3
      rigFinger.pip.worldDirection  = new THREE.Vector3
      rigFinger.dip.worldDirection  = new THREE.Vector3

      rigFinger.    worldUp         = new THREE.Vector3
      rigFinger.mcp.worldUp         = new THREE.Vector3
      rigFinger.pip.worldUp         = new THREE.Vector3
      rigFinger.dip.worldUp         = new THREE.Vector3

      rigFinger.    positionLeap   = new THREE.Vector3
      rigFinger.mcp.positionLeap   = new THREE.Vector3
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

  THREE.Matrix3.prototype.multiplyMatrices = (a, b)->
    ae = a.elements
    be = b.elements

    `
    var result = [];
    for(var row = 0; row < 3; ++row) {
      result[row] = [];
      for(var col = 0; col < 3; ++col) {
        result[row][col] = 0;
        for(var con = 0; con < 3; ++con) {
          result[row][col] += ae[row * 3 + con] * be[con * 3 + col];
        }
      }
    }`

    @elements = result[0].concat(result[1]).concat(result[2])
    @




  {
    frame: (frame)->
      scope.stats.begin() if scope.stats
      for leapHand in frame.hands
        handMesh = leapHand.data('riggedHand.mesh')
        palm = handMesh.palm

        palm.positionLeap.fromArray(leapHand.palmPosition)
        # wrist -> mcp -> pip -> dip -> tip
        for mcp, i in palm.children
          mcp.    positionLeap.fromArray(leapHand.fingers[i].carpPosition)
          mcp.mcp.positionLeap.fromArray(leapHand.fingers[i].mcpPosition)
          mcp.pip.positionLeap.fromArray(leapHand.fingers[i].pipPosition)
          mcp.dip.positionLeap.fromArray(leapHand.fingers[i].dipPosition)
          mcp.tip.positionLeap.fromArray(leapHand.fingers[i].distal.nextJoint)


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

        palm.children[0].worldQuaternion = palm.worldQuaternion
        palm.children[0].worldUp = palm.worldUp

#        for carp in palm.children
#          carp.traverse (bone)->
#            if bone.children[0]
#              bone.worldDirection.subVectors(bone.children[0].positionLeap, bone.positionLeap).normalize()
#              bone.positionFromWorld(bone.children[0].positionLeap, bone.positionLeap)



        # source is leap
        # target is model
        equivalentChildBasis = (sourceParentBasis, sourceChildBasis, targetParentBasis)->
          relativeRotation = Transpose(sourceParentBasis) * sourceChildBasis;
          targetChildBasis = targetParentBasis * relativeRotation;
          return targetChildBasis

        absoluteTransformation = (sourceParentBasis, sourceChildBasis, targetParentBasis)->
          absoluteRotation = sourceChildBasis * Transpose(sourceParentBasis);
          return absoluteRotation



        leapParentBasis = leapHand.indexFinger.metacarpal.basis
        sourceParentBasisT = (new THREE.Matrix3)
        sourceParentBasisT.elements = leapParentBasis[0].concat(leapParentBasis[1]).concat(leapParentBasis[2])
        sourceParentBasis = sourceParentBasisT.clone().transpose()

        leapChildBasis = leapHand.indexFinger.proximal.basis
        sourceChildBasisT = (new THREE.Matrix3)
        sourceChildBasisT.elements = leapChildBasis[0].concat(leapChildBasis[1]).concat(leapChildBasis[2])
        sourceChildBasis = sourceChildBasisT.clone().transpose()

        arrow.setRotationFromMatrix( sourceParentBasis  )
        arrow2.setRotationFromMatrix( sourceChildBasis )

        # input: two left handed basis
        # returns on right handed basis
        targetChildBasis = (new THREE.Matrix3).multiplyMatrices(sourceParentBasisT, sourceChildBasis)
        te = targetChildBasis.elements

        # conversion for right-handed basis
        # NOTE: Because targetParentBasis was right handed there is no chiral conversion here.
        # NOTE: If tagetParentBasis were left handed, te[0], te[1] and te[2] would be negate,
        # since targetChildMatrix is required to be a rotation.
        # In the left handed case, the rotation is relative to a global basis in which the reflection
        # is defined by the negation of the first basis vector.
        targetChildMatrix = (new THREE.Matrix4)
        targetChildMatrix.elements = [
          te[0],
          te[1],
          te[2],
          0,
          te[3],
          te[4],
          te[5],
          0
          te[6],
          te[7],
          te[8],
          0,
          0,
          0,
          0,
          1
        ]


        isOronormal = (mat3)->
          transpose = mat3.clone().transpose()
          result = (new THREE.Matrix3).multiplyMatrices(mat3, transpose).elements
          `var sum2 = 0;
            for (var row = 0; row < 3; ++row) {

              for(var col = 0; col < 3; ++col) {
                if(row === col) {
                  sum2 += (result[row * 3 + col] - 1) * ( result[row * 3 + col] - 1 );
                } else {
                  sum2 +=  result[row * 3 + col]      *   result[row * 3 + col];
                }
              }

            }`
          console.assert(sum2 < 0.00001);
#          debugger

#        isOronormal(sourceChildBasis)
#        isOronormal(sourceParentBasis)
        isOronormal(targetChildBasis)

        targetChildMatrix.elements.map = Array.prototype.map
#        document.getElementById('debug').innerHTML = targetChildMatrix.elements.map((e) -> return e.toPrecision(4))

        arrow3.setRotationFromMatrix(
          targetChildMatrix
        );
        arrow3.quaternion

        palm.children[1].mcp.matrix = arrow3.matrix
        palm.children[1].mcp.quaternion.setFromRotationMatrix(targetChildMatrix)

        document.getElementById('debug').innerHTML = palm.children[0].mcp.quaternion.toArray().map((e) -> return e.toPrecision(4))

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