//--------------------------------//
//                                //
//  Author: Tiago Lobato Gimenes  //
//  email: tlgimenes@gmail.com    //
//                                //
//--------------------------------//

#ifndef CLGLPARSER_HPP
#define CLGLPARSER_HPP

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <iostream>

class CLGLParser
{
  public:
    std::string kernel;
    std::string kernelFile;
    std::string dataFile;
    int curKernel;
    int particlesNum;
    bool dataFileSet;
    float rungeStep;

    CLGLParser(int argc, char * argv[]);
    bool isDataFileSet(void);
};

#endif
