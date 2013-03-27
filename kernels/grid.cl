//------------------------------------//
//                                    //
//  Author : Tiago Lobato Gimenes     //
//  email : tlgimenes at gmail.com    //
//                                    //
//------------------------------------//

// Enable ATOMIC Functions
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_extended_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_extended_atomics : enable

// Add the main distance to the sideSize, after the
// execution of the kernel we must divide sideSize 
// by n
__kernel void getGridSideSize(
    __global float4 * pos,
    __global int * sideSize,
    int n)
{
  __private uint i = get_global_id(0);
  __private uint j = (i+1) % n;
  __private float4 dist1, dist2,

  if(i < n){
    dist1 = pos[i];
    dist2 = pos[j];
    dist1.w = 0;
    dist2.w = 0;
    atomic_add(sideSize, fast_distance(dist1, dist2));
  }

  return;
}

// Get the ngridCubes values and set the gridCoord index. This 
// function should be used to initialize the nGridCubes and 
// gridCoord, and for anything else
__kernel void getNGridCubes(
    __global float4 * pos,
    __global int4 * gridCoord,
    __global int * nGridCubes,
    __global int * sideSize,
    int n)
{
  __private uint i = get_global_id(0);
  __private int4 p;

  if(i < n){
    p = convert_int4_rtz(pos[i]); //convert the position to int
    gridCoord[i] = p / *sideSize; //get the coord in the grid
    gridCoord[i].w = i;           //set the index of the corresponding position in pos array
    p = gridCoord[i];             // private is faster
    
    // Atomic functions
    atomic_max(nGridCubes, p.x);  
    atomic_max(nGridCubes, p.y);
    atomic_max(nGridCubes, p.z);
  }
  
  return;
}

// This function set the index values and can be used more than
// one time
__kernel void setGridIndex(
    __global float4 * pos,
    __global int * gridIndex,
    __global int4 * gridCoord, 
    __global int * nGridCubes,
    __global int * sideSize,
    int n)
{
  __private unsigned int i = get_global_id(0);
  __private int gridCubes = *nGridCubes;
  __private int4 aux;

  if(i < n){
    aux = gridCoord[i];
    gridIndex[i] = (aux.x * gridCubes * gridCubes) + (aux.y * gridCubes) + (aux.z);
  }

  return;
}

// Bubble sort for the even index
__kernel void bubbleSort3D_even(
    __global int * gridIndex,
    __global int4 * gridCoord,
    __global bool * modification,
    int n)
{
  __private uint i = get_global_id(0) * 2;
  __private int4 aux;

  if(i < n-1){
    if(gridIndex[i] > gridIndex[i+1]){
      aux.x = gridIndex[i];
      gridIndex[i] = gridIndex[i+1];
      gridIndex[i+1] = aux.x;

      aux = gridCoord[i];
      gridCoord[i] = gridCoord[i+1];
      gridCoord[i+1] = aux;

      *modification = true;
    }
  }
}

// bubble sort for the odd index
__kernel void bubbleSort3D_odd(
    __global int * gridIndex,
    __global int4 * gridCoord,
    __global bool * modification,
    int n)
{
  __private uint i = 1 + get_global_id(0) * 2;
  __private int4 aux;

  if(i < n-1){
    if(gridIndex[i] > gridIndex[i+1]){
      aux.x = gridIndex[i];
      gridIndex[i] = gridIndex[i+1];
      gridIndex[i+1] = aux.x;

      aux = gridCoord[i];
      gridCoord[i] = gridCoord[i+1];
      gridCoord[i+1] = aux;

      *modification = true;
    }
  }
}

void getNeighbors(
    __global int * gridIndex,
    __private int actualIndex,
    __private int * begin,
    __private int * end)
{
  while(gridIndex[*begin] == gridIndex[actualIndex])
    (*begin)--;
  while(gridIndex[*end] == gridIndex[actualIndex])
    (*end)++;

  (*begin)++;
  (*end)--;
  return;
}
