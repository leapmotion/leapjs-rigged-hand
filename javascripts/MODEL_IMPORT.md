Importing a model can be quite tricky.

The hand is created in Maya, and needs to be opened by ThreeJS.  This must include:
  - The mesh (faces, vertices, normals)
  - Materials
  - Scale
  - Bones
  - Skin Weights and Skin Indices (these connect vertices to bones)


The ThreeJS JSONLoader must be used to import armature (skinned mesh) in to ThreeJS.  Most import/export tools
 do not support this.  Blender's is one of the few that does.

In order for a file to be imported in blender, it must be exported as a .dae