 
  var HEIGHT, WIDTH;

  var renderer, scene, camera, animation;

  var directionalLight, pointLight;

  var sphere, rectangle , handMesh;

  //Global Leap Data for debugging:
  var leapHand;

  var sceneSize = 100;

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


    camera = new THREE.PerspectiveCamera(90, WIDTH / HEIGHT, 10, 1000);
    camera.position.z = -sceneSize;
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
    loader.load( 'javascripts/riggedHand.js' , function( geometry , materials ){

      for (var i = 0; i < materials.length; i++) {
        var mat = materials[i];

        mat.skinning = true;
      }

      handMesh = new THREE.SkinnedMesh(
        geometry,
        new THREE.MeshFaceMaterial(materials)
      );

      handMesh.rotation.z = Math.PI / 100;

      var baseEuler = new THREE.Euler(-Math.PI / 2, 0, -Math.PI / 2, 'XYZ');
      baseQuaternion = new THREE.Quaternion().setFromEuler( baseEuler);
      handMesh.quaternion = baseQuaternion;


      scene.add( handMesh );

      controller = new Leap.Controller();
      controller.on( 'frame' ,function(){
       
        console.log('HWOS');
        
      });

      controller.on( 'connect' , function(){

        console.log('YUP');

      });
      controller.connect();

      console.log( controller );

      
    });

    
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
       
    console.log('frame' );
    if ( frame.hands[0] ) {
     
      leapHand = frame.hands[0];

      var spp =  leapHand.stabilizedPalmPosition;
      handMesh.position = leapToScene( frame , spp );

      handMesh.quaternion = baseQuaternion.clone();
      
      var x = leapHand.roll();
      var y = leapHand.direction[1];
      var z = -leapHand.direction[0];
      
      var newEuler = new THREE.Euler( x , y , z , 'XYZ') 
      var newQuat = new THREE.Quaternion().setFromEuler( newEuler );
     
      handMesh.quaternion.multiply(newQuat);

      for( var i = 0; i < leapHand.fingers.length; i++ ){

        var f = leapHand.fingers[i];
        var mcp = leapToScene( frame , f.mcpPosition );

      }


      console.log('HO');
    
    }
      
  }



