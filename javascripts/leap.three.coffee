Leap.plugin 'threejs', ->
  {
    frame: (frame)->
      for hand in frame.hands
        # for convenience, we sort the fingers
        hand.fingers = _.sortBy(hand.fingers, (finger)-> finger.id)

        for finger in hand.fingers
          finger.mcpPosition = (new THREE.Vector3).fromArray(finger.mcpPosition)
          finger.pipPosition = (new THREE.Vector3).fromArray(finger.pipPosition)
          finger.dipPosition = (new THREE.Vector3).fromArray(finger.dipPosition)
          finger.tipPosition = (new THREE.Vector3).fromArray(finger.tipPosition)
  }