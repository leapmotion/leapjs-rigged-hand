window.TO_RAD = Math.PI / 180
window.TO_DEG = 1 / TO_RAD
window.zeroVector = new THREE.Vector3(0,0,0)
# accepts three points in two lines, with b being the join.
THREE.ArrowHelper.prototype.label = (text, scale = 1, flip = false)->
  text = new THREE.Mesh(
    new THREE.TextGeometry(text, {
      size: this.line.scale.y / 20 * scale,
      height: this.line.scale.y / 100 * scale
    }),
    new THREE.MeshBasicMaterial( color: @line.material.color )
  )
  if flip
    text.rotation = new THREE.Euler(180 * TO_RAD,180 * TO_RAD,90 * TO_RAD)
    text.position = vec3(0,4,0)
  else
    text.rotation = new THREE.Euler(0,0,90 * TO_RAD)
    text.position = vec3(-0.1,0,0)

  @add(text)


THREE.Vector3.prototype.quick = ->
  [
    @x.toPrecision(2)
    @y.toPrecision(2)
    @z.toPrecision(2)
  ]

window.vec3 = (x,y,z)->
  (new THREE.Vector3(x,y,z))



# for some reason, we can't store custom properties on the Vector3
# we return an arrow and expect it to be passed back
THREE.Vector3.prototype.visualize = (parent, color, options = {})->
  options.length ||= 10
  if @_arrow
    @_arrow.setDirection(@)
  else
    @_arrow = new THREE.ArrowHelper(
      @, # direction
      options.from || new THREE.Vector3(0,0,0), # origin
      options.length, # length
      color
    )
    @_arrow.label(options.label, 1, options.flip) if options.label
    parent.add @_arrow
  @

THREE.Vector3.prototype.visualizeFrom = (position)->
  @_arrow.position = position
  @

THREE.Vector3.prototype.visualizeFromPosition = ->
  @_arrow.position = @position
  @
