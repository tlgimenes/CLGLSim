//------------------------------------//
//                                    //
//  Author : Tiago Lobato Gimenes     //
//  email : tlgimenes@gmail.com       //
//                                    //
//------------------------------------//

#define G 0.004302
/*#define G 1*/
#define MIN_DISTANCE 0.02
#define MAX_DISTANCE 100000.00

__kernel void  Gravity_rk1(
    __constant float * mass, 
    __global float4 * vel,
    __global float4 * pos, 
    float rungeStep, 
    int n)
{
  __private unsigned int i = get_global_id(0);

  // Private variables improves the kernel speed
  __private float4 posCur, velCur;
  __private float4 aRes = {0.0, 0.0, 0.0, 0.0};
  __private float r;

  __private float4 aux;

  if(i < n){
    posCur = pos[i];
    velCur = vel[i];
    for(int j = 0; j < n; j++){
      aux = pos[j] - posCur;
      r = dot(aux, aux);
      if(r <= MIN_DISTANCE || r >= MAX_DISTANCE) 
        continue;
      aRes += G * mass[j] * (aux) * rsqrt(r) / r;
    }
    vel[i] = velCur + aRes * rungeStep;
    pos[i] = posCur + velCur * rungeStep;
  }
}

// kernel Runge-Kutta 2
__kernel void Gravity_rk2(
    __constant float * mass, 
    __global float4 * vel,
    __global float4 * pos, 
    float rungeStep, 
    int n)
{
  __private unsigned int cur = get_global_id(0);

  // Private variables improves the kernel speed
  __private float4 velCur, posCur, posAux;
  __private float4 aRes[2];
  __private float4 dist[2];

  __private float4 reset = {0.0, 0.0, 0.0, 0.0};

  //Runge Kutta 2 variables
  __private float4 kPos[2];
  __private float4 kVel[2];

  __private float r[2];

  if(cur < n){
    //Iniciate variables
    aRes[0] = aRes[1] = reset;

    posCur = pos[cur];
    velCur = vel[cur];

    posAux = rungeStep * velCur;
    for(int i=0; i < n; i++){
      dist[0] = pos[i] - posCur;
      dist[1] = dist[0] + posAux;
      r[0] = dot(dist[0], dist[0]);
      r[1] = dot(dist[1], dist[1]);
      if(r[0] <= MIN_DISTANCE || r[0] >= MAX_DISTANCE)
        continue;
      aRes[0] += G * mass[i] * dist[0] * rsqrt(r[0]) / r[0];
      aRes[1] += G * mass[i] * dist[1] * rsqrt(r[1]) / r[1];
    }
    kPos[0] = 2.0f * velCur;
    kVel[0] = aRes[0];
    kPos[1] = rungeStep * aRes[0];
    kVel[1] = aRes[1];

    pos[cur] += (kPos[0] + kPos[1]) * rungeStep / 2.0f;
    vel[cur] += (kVel[0] + kVel[1]) * rungeStep / 2.0f; 
  }
}

// kernel for Runge-Kutta 4 method
__kernel void Gravity_rk4(
    __constant float * mass, 
    __global float4 * vel,
    __global float4 * pos,
    float rungeStep, 
    int n)
{
  // Get Proccess Global ID
  __private unsigned int cur = get_global_id(0);

  // Runge Kutta 4 variables;
  __private float4 kPos[4];
  __private float4 kVel[4];

  // Total acceleration pull
  __private float4 aRes = {0.0, 0.0, 0.0, 0.0};

  // Distance
  __private float r;
  __private float4 dist;

  // Reset to 0 float4 variable
  __private float4 reset = {0.0, 0.0, 0.0, 0.0};

  // Put current particle data in
  // local variables for speed !!
  __private float4 posCur;
  __private float4 posInit;
  __private float4 velCur;
  __private float4 velInit;

  if(cur < n){
    posCur = posInit = pos[cur];
    velCur = velInit = vel[cur];

    // Get k_v[0] and k_r[0]
    for(int i = 0; i < n; i++){
      dist = pos[i] - posCur;
      r = dot(dist, dist);
      // If it is good to iterate with the particle i
      if(r <= MIN_DISTANCE || r >= MAX_DISTANCE)
        continue;
      aRes += G * mass[i] * dist * rsqrt(r) / r;
    }
    kVel[0] = aRes * rungeStep;
    kPos[0] = velCur * rungeStep;

    // Get k_v[1] and k_r[1]
    posCur = posInit + kPos[0] / 2.0f;
    velCur = velInit + kVel[0] / 2.0f;
    aRes = reset;
    for(int i = 0; i < n; i++){
      dist = pos[i] - posCur;
      r = dot(dist, dist);
      // If it is good to iterate with the particle i
      if(r <= MIN_DISTANCE || r >= MAX_DISTANCE)
        continue;
      aRes += G * mass[i] * dist * rsqrt(r) / r;
    }
    kVel[1] = aRes * rungeStep;
    kPos[1] = velCur * rungeStep;

    // Get k_v[2] and k_r[2]
    posCur = posInit + kPos[1] / 2.0f;
    velCur = velInit + kVel[1] / 2.0f;
    aRes = reset;
    for(int i = 0; i < n; i++){
      dist = pos[i] - posCur;
      r = dot(dist, dist);
      // If it is good to iterate with the particle i
      if(r <= MIN_DISTANCE || r >= MAX_DISTANCE)
        continue;
      aRes += G * mass[i] * dist * rsqrt(r) / r;
    }
    kVel[2] = aRes * rungeStep;
    kPos[2] = velCur * rungeStep;

    // Get k_v[3] and k_r[3]
    posCur = posInit + kPos[2];
    velCur = velInit + kVel[2];
    aRes = reset;
    for(int i = 0; i < n; i++){
      dist = pos[i] - posCur;
      r = dot(dist, dist);
      // If it is good to iterate with the particle i
      if(r <= MIN_DISTANCE || r >= MAX_DISTANCE)
        continue;
      aRes += G * mass[i] * dist * rsqrt(r) / r;
    }
    kVel[3] = aRes * rungeStep;
    kPos[3] = velCur * rungeStep;

    // Calculate the final Position
    vel[cur] = velInit + (kVel[0] + 2*(kVel[1] + kVel[2]) + kVel[3]) / 6.0f;
    pos[cur] = posInit + (kPos[0] + 2*(kPos[1] + kPos[2]) + kPos[3]) / 6.0f;
  }
}
