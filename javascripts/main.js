 
  var HEIGHT, WIDTH;

  var renderer, scene, camera, animation;

  var directionalLight, pointLight;

  var sphere, rectangle , handMesh;

  //Global Leap Data for debugging:
  var leapHand;

  var sceneSize = 20;

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


    camera = new THREE.PerspectiveCamera(90, WIDTH / HEIGHT, sceneSize / 100 , 1000);
    camera.position.z = sceneSize;
    camera.lookAt(new THREE.Vector3());

    scene = new THREE.Scene();

    scene.add(camera);
    scene.add(new THREE.AxisHelper(50));
    
    //Lights!
    scene.add(new THREE.AmbientLight(0x222222));

    directionalLight = new THREE.DirectionalLight(0xffffff, 0.5);
    directionalLight.position.set(0, 1, 1000);
    scene.add(directionalLight);

    pointLight = new THREE.PointLight(0xFFffff);
    pointLight.position = new THREE.Vector3(20, 20, 10);
    pointLight.lookAt(new THREE.Vector3(0, 0, 10));

    scene.add(pointLight);


    // Objects
    rectangle = new THREE.Mesh(
        new THREE.CubeGeometry(4, 1, 8), 
        new THREE.MeshPhongMaterial({
          color: 0x00ff00
        })
    );

    scene.add(rectangle);

    sphere = new THREE.Mesh(
        new THREE.SphereGeometry(1), 
        new THREE.MeshPhongMaterial({
          color: 0xff0000
        })
    );
    sphere.position.set(10, 10, 0);

    scene.add(sphere);

    var loader = new THREE.JSONLoader();

    loader.load('handModel2/riggedHand.js', function (geometry, materials) {
      var hand, material;

      handMesh = new THREE.SkinnedMesh(
        geometry,
        new THREE.MeshFaceMaterial(materials)
      );

      material = handMesh.material.materials;

      for (var i = 0; i < materials.length; i++) {
        var mat = materials[i];

        mat.skinning = true;
      }
        
      var baseEuler = new THREE.Euler(0, -Math.PI/2, 0, 'XYZ');
      
      handMesh.rotation = baseEuler;
        
      scene.add( handMesh );

      controller = new Leap.Controller();
      controller.on( 'frame' , leapLoop );
      controller.connect();

    });

    /*loader.load( 'handModel/blender.json' , function( geometry , materials ){

      new THREE.SceneLoader().load( 'handModel/fbxPy.json' , function(object ){

        //console.log( object );

        geometry.faces = object.geometries.Geometry_64_g0_01.faces;
        geometry.vertices = object.geometries.Geometry_64_g0_01.vertices;

        materials = object.materials ;
        THREE.GeometryUtils.center(geometry);
        
       
        console.log( geometry );
        
      
        object.materials.phong1.skinning = true;
        handMesh = new THREE.SkinnedMesh( geometry, object.materials.phong1);
        handMesh.useVertexTexture = false
        handMesh.scale = new THREE.Vector3(0.01,0.01,0.01)

        handMesh.rotation.z = Math.PI / 100;

        var baseEuler = new THREE.Euler(-Math.PI / 2, 0, -Math.PI / 2, 'XYZ');
        baseQuaternion = new THREE.Quaternion().setFromEuler( baseEuler );
        handMesh.quaternion = baseQuaternion;

        scene.add( handMesh );

        controller = new Leap.Controller();
        controller.on( 'frame' , leapLoop );
        controller.connect();

      });

      
    });*/

    render();

    
  }

  function Vector3( v ){

   // console.log( v );
    var vector = new THREE.Vector3( v[0] , v[1] , v[2] );
    return vector

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

      var matrix = new THREE.Matrix4(
      
          -cross.x  , -norm.x , -dir.x  , 0 ,
          -cross.y  , -norm.y , -dir.y  , 0 ,
          -cross.z  , -norm.z , -dir.z  , 0 ,
          0         , 0       , 0       , 1 

      );

      handMesh.rotation.setFromRotationMatrix( matrix );
      //console.log( matrix );


      //handMesh.quaternion = baseQuaternion.clone();
      /*
      var x = leapHand.roll();
      var y = leapHand.yaw();
      var z = leapHand.pitch();
      
      var newEuler = new THREE.Euler( x , z , y , 'XYZ') 
      var newQuat = new THREE.Quaternion().setFromEuler( newEuler );
     
      handMesh.quaternion.multiply(newQuat);
      */

      //TODO:
      //apply to thumb as well. 
      // Our rigged hand doesn't have the amount of
      // bones in thumb!
      for( var i = 1; i < leapHand.fingers.length; i++ ){

        
        var f = leapHand.fingers[i];
        var mcp = leapToScene( frame , f.mcpPosition );
        var pip = leapToScene( frame , f.pipPosition );
        var dip = leapToScene( frame , f.dipPosition );
        var tip = leapToScene( frame , f.tipPosition );

        var lh = leapHand;
        var d = lh.palmPosition;

        handDir = new THREE.Vector3( d[0] , d[1] , d[2] ).normalize();

        mcpToPip = new THREE.Vector3().subVectors( pip , mcp ).normalize();
        pipToDip = new THREE.Vector3().subVectors( dip , pip ).normalize();
        dipToTip = new THREE.Vector3().subVectors( pip , tip ).normalize();


        var mcpBone         = findBone( handMesh , i , 0 );
        mcpFromTo           = quaternionFromTo( handDir , mcpToPip );
        mcpBone.quaternion  = mcpFromTo.multiply( handMesh.quaternion );

       // console.log( mcpBone.quaternion );

        mcpBone.rotation.setFromQuaternion( mcpBone.quaternion , 'XYZ' );
        //console.log( mcpBone.rotation );
       
        var pipBone         = findBone( handMesh , i , 1 );
        pipFromTo           = quaternionFromTo( mcpToPip , pipToDip );

        pipBone.quaternion  = pipFromTo.multiply( mcpBone.rotation._quaternion );

        //console.log( pipBone.quaternion );
        pipBone.rotation.setFromQuaternion( pipBone.quaternion , 'XYZ' );

        var dipBone         = findBone( handMesh , i , 2 );
        dipFromTo           = quaternionFromTo( pipToDip , dipToTip );
        dipBone.quaternion  = dipFromTo.multiply( pipBone.rotation._quaternion );
        dipBone.rotation.setFromQuaternion( dipBone.quaternion , 'XYZ' );
        
      }

      handMesh.geometry.verticesNeedsUpdate = true;
    
    }
      
  }

  
  function findBone( mesh , finger , whichBone ){

    var bones = mesh.bones;

    var index = finger * 4 + whichBone + 1;

    return bones[index];

  }


  // TODO: the hard stuff!
  function quaternionFromTo(from , to){

    var fromNorm  = from.clone().normalize();
    var toNorm    = to.clone().normalize();

    var axis  = fromNorm.cross( toNorm );
    var angle = Math.asin( axis.length() ); 


    return new THREE.Quaternion().setFromAxisAngle( axis , angle );
  }


