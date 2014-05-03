//
//  Shader.fsh
//  openglGame
//
//  Created by Cyrille Fauvel on 10/30/13.
//  Copyright (c) 2013 Autodesk. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
