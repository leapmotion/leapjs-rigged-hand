 
  var HEIGHT, WIDTH;

  var renderer, scene, camera, animation;

  var directionalLight, pointLight;

  var sphere, rectangle , handMesh;

  var xDom , yDom , zDom , wDom;
  //Global Leap Data for debugging:
  var leapHand;

  var bones = [];

  var sceneSize = 20;

  var ROTATION = 0;

  init();

  function init(){

    // Getting the height and width of the window
    HEIGHT = window.innerHeight;
    WIDTH = window.innerWidth;

    renderer = new THREE.WebGLRenderer({
      alpha: true
    });

    renderer.setClearColor(0x000000, 1);
    renderer.setSize(WIDTH, HEIGHT);

    document.getElementById('threejs').appendChild(renderer.domElement);
http://stackoverflow.com/questions/18752146/blender-exports-a-three-js-animation-bones-rotate-strangely

    camera = new THREE.PerspectiveCamera(90, WIDTH / HEIGHT, sceneSize / 100 , 1000);
    camera.position.z = sceneSize;
    //camera.position.y = sceneSize;
    camera.lookAt(new THREE.Vector3());

    scene = new THREE.Scene();

    scene.add(camera);
  
    xDom = document.createElement('div');
    xDom.style.color = '#ffffff';
    xDom.style.zIndex = 999;
    xDom.style.position = 'absolute';
    //console.log( xDom.style );
    xDom.style.top = 0;
    console.log( xDom.style.top );

    document.body.appendChild( xDom );

    yDom = document.createElement('div');
    yDom.style.color = '#ffffff';
    yDom.style.zIndex = 999;
    yDom.style.position = 'absolute';
    yDom.style.top = 20;

    document.body.appendChild( yDom );

    zDom = document.createElement('div');
    zDom.style.color = '#ffffff';
    zDom.style.zIndex = 999;
    zDom.style.position = 'absolute';
    zDom.style.top = 40;

    document.body.appendChild( zDom );

    wDom = document.createElement('div');
    wDom.style.color = '#ffffff';
    wDom.style.zIndex = 999;
    wDom.style.position = 'absolute';
    wDom.style.top = 60;

    document.body.appendChild( wDom );

    
    //Lights!
    scene.add(new THREE.AmbientLight(0x222222));

    directionalLight = new THREE.DirectionalLight(0xff0000,2.5);
    directionalLight.position.set(0, 0, 1000);
    scene.add(directionalLight);

    directionalLight = new THREE.DirectionalLight(0x00ff00,2.5);
    directionalLight.position.set(0, 1000,0);
    scene.add(directionalLight);

    directionalLight = new THREE.DirectionalLight(0x0000ff,2.5);
    directionalLight.position.set(500, 1000,0);
    scene.add(directionalLight);

    pointLight = new THREE.PointLight(0x00ff00);
    pointLight.position = new THREE.Vector3(20, 20, 10);
    pointLight.lookAt(new THREE.Vector3(0, 0, 10));

    var loader = new THREE.JSONLoader();

    //'javascripts/romanRig.js'
    loader.load('javascripts/14right.json', function (geometry, materials) {
      var hand, material;

      console.log('GEO' );
      console.log( geometry );

      console.log( 'MAT' );
      console.log( materials );

      for( var i  = 0; i < geometry.bones.length; i++ ){

        var b = geometry.bones[i];
        for(var l = 0; l < b.pos.length; l++ ){
          b.pos[l] *= 100;
        }

      }


      for (var i = 0; i < materials.length; i++) {
        var mat = materials[i];

        mat.wireframe = true;
       // mat.transparent = true;
       // mat.opacity = .1;
        //mat.skinning = true;
      }
      

      var material = materials[0];

      console.log( material );


      //////////////////material.skinning = true;

      handMesh = new THREE.SkinnedMesh(
        geometry,
        material
        // new THREE.MeshFaceMaterial(materials)
      );
      
      var geo = new THREE.IcosahedronGeometry( .5 , 1 );
      var mat = new THREE.MeshNormalMaterial();

      var mesh = new THREE.Mesh( geo , mat );

      createRig( handMesh , mesh );


      var baseEuler = new THREE.Euler(Math.PI/2,0,0 , 'XYZ');

      baseMatrix = new THREE.Matrix4().makeRotationFromEuler( baseEuler , 'XYZ' );
      
      handMesh.rotation = baseEuler;

      handMesh.scale.multiplyScalar( 1 );
        
      scene.add( handMesh );


      controller = new Leap.Controller();
      controller.on( 'frame' , leapLoop );
      controller.connect();

    });

    render();

    
  }

  function Vector3( v ){

   // console.log( v );
    var vector = new THREE.Vector3( v[0] , v[1] , v[2] );
    return vector

  }


  function  createRig( whichMesh , mesh ){


    for( var i = 0; i < whichMesh.bones.length; i++ ){

      var bone = whichMesh.bones[i];

      if( bone.parent == whichMesh ){
     
        createBone( bone , whichMesh, mesh );

      }

    }

  }

  function createBone( bone , parent , mesh ){

    console.log( bone );

    var m = mesh.clone();
    parent.add( m );
    m.position = bone.position;
    m.rotation = bone.rotation;

    for( var i = 0 ; i < bone.children.length; i ++ ){

      var childBone = bone.children[i];
      createBone( childBone , m , mesh );


    }

  }


  function leapToScene( frame , position ){

    var x = position[0] - frame.interactionBox.center[0];
    var y = position[1] - frame.interactionBox.center[1];
    var z = position[2] - frame.interactionBox.center[2];
      
    x /= frame.interactionBox.size[0];
    y /= frame.interactionBox.size[1];
    z /= frame.interactionBox.size[2];

    x *= sceneSize;
    y *= sceneSize;
    z *= sceneSize;

    z -= sceneSize;

    return new THREE.Vector3( x , y , z );

  }


  function render(){

    renderer.render( scene, camera );
    requestAnimationFrame( render );

  }

  
  function leapLoop(frame) {
      
    if ( frame.hands[0] ) {
     
      leapHand = frame.hands[0];

      var spp =  leapHand.stabilizedPalmPosition;
      handMesh.position = leapToScene( frame , spp );

      var dir   = Vector3( leapHand.direction );
      var norm  = Vector3( leapHand.palmNormal );
      var cross = new THREE.Vector3().crossVectors( dir , norm );
      
      //BASIS CHOICE:
      //Index Finger == -Z == dir
      //Middle Finger == -Y == norm
      //Thumb == -X == cross

      var handMatrix = new THREE.Matrix4(
      
          -cross.x  , -norm.x , -dir.x  , 0 ,
          -cross.y  , -norm.y , -dir.y  , 0 ,
          -cross.z  , -norm.z , -dir.z  , 0 ,
          0         , 0       , 0       , 1 

      );

      var rotatedHandMatrix = handMatrix.clone().multiply( baseMatrix );
      handMesh.rotation.setFromRotationMatrix( rotatedHandMatrix );



      // Skipping thumb for now
      //for( var i = 1; i < leapHand.fingers.length; i++ ){

        i = 2;
        
        var f = leapHand.fingers[i];
        var palm  = leapToScene( frame , leapHand.palmPosition );
        var mcp   = leapToScene( frame , f.mcpPosition );
        var pip   = leapToScene( frame , f.pipPosition );
        var dip   = leapToScene( frame , f.dipPosition );
        var tip   = leapToScene( frame , f.tipPosition );

        var palmDirection = Vector3( leapHand.direction );
        
        //console.log( palmDirection );
        var palmToMcp =  mcp.clone().sub( palm ).normalize();
        var mcpToPip  =  pip.clone().sub( mcp );//.normalize();
        var pipToDip  =  dip.clone().sub( pip ).normalize();
        var dipToTip  =  tip.clone().sub( dip ).normalize();

        var mainRotation = new THREE.Quaternion().setFromRotationMatrix( handMatrix );
        var baseRotation = new THREE.Quaternion().setFromRotationMatrix( baseMatrix );

        var inverseBase = new THREE.Matrix4().getInverse( baseMatrix );
        var inverseBaseRotation = new THREE.Quaternion().setFromRotationMatrix( inverseBase );

        var inverseMain = new THREE.Matrix4().getInverse( handMatrix );
        var inverseMainRotation = new THREE.Quaternion().setFromRotationMatrix( inverseMain );
       
        var c = quaternionFromTo( new THREE.Vector3( 1 , 0 , 0 ), new THREE.Vector3( 0 , 1 , 0 ) );
       
        printQuaternion( c );

        var mcpBone = findBone( handMesh, i , 0 );
        var mcpRotation = quaternionFromTo( palmDirection , mcpToPip );
        //mcpRotation.multiply( mainRotation );
        
        //mcpRotation.multiply( baseRotation );
       // mcpRotation.multiply( inverseMainRotation );

 

        //wDom.innerHTML = "W: " + mcpRotation.w;

        /*xDom.innerHTML = "X: " + mcpBone.rotation.x;
        yDom.innerHTML = "Y: " + mcpBone.rotation.y;
        zDom.innerHTML = "Z: " + mcpBone.rotation.z;
        wDom.innerHTML = "W: " + mcpBone.rotation.w;*/
       
        //mcpBone.rotation.setFromQuaternion( baseRotation );

        //mcpBone.rotation.setFromQuaternion( mcpRotation );
        //mcpBone.rotation = mcpRotation;


        //mcpBone.rotation.y = ROTATION;

        var pipBone = findBone( handMesh, i , 1 );
        /*var pipRotation = quaternionFromTo( mcpToPip , pipToDip );
        pipRotation.multiply( mainRotation );
        pipBone.rotation.setFromQuaternion( pipRotation );*/
        //pipBone.rotation.y = ROTATION;
        
        var dipBone = findBone( handMesh, i , 2 );
        /*var dipRotation = quaternionFromTo( pipToDip , dipToTip );
        dipRotation.multiply( mainRotation );
        dipBone.rotation.setFromQuaternion( dipRotation );*/
        //dipBone.rotation.y = ROTATION;







    //}

     }


    ROTATION += .01;
    
    
    handMesh.geometry.verticesNeedsUpdate = true;

      
  }

 
  function findBone( mesh , finger , whichBone ){

    var bones = mesh.bones;

    var f = 4 - finger;

    var index = 3 + whichBone + f * 4
   // 3 ,  0  =


    //index 

    return bones[index];

  }

  function printQuaternion( q ){

    xDom.innerHTML = "X: " + q.x;
    yDom.innerHTML = "Y: " + q.y;
    zDom.innerHTML = "Z: " + q.z;
    wDom.innerHTML = "W: " + q.w;

  }

  // TODO: the hard stuff!
  function quaternionFromTo(from , to){

    var fromNorm  = from.clone().normalize();
    var toNorm    = to.clone().normalize();

    var axis  = fromNorm.cross( toNorm );
    var angle = Math.asin( axis.length() ); 

    //console.log( 'hello; ' );
    //console.log( axis );
    //return new THREE.Quaternion(angle, axis[0] , axis[1] , axis[2]  );


    return new THREE.Quaternion().setFromAxisAngle( axis , angle );

  }


