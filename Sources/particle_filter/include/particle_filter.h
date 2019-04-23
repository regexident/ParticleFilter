#ifndef particle_filter_h
#define particle_filter_h

#include <simd/simd.h>

typedef struct {
    vector_float3 xyz;
    float weight;
} particle_t;

typedef struct {
    vector_float3 xyz;
    float value;
} observation_t;

typedef struct {
    float std_deviation;
} motion_model_t;

typedef struct {
    float std_deviation;
} observation_model_t;

typedef struct {
    motion_model_t motion;
    observation_model_t observation;
} model_t;

typedef struct {
    float sum;
    float neff;
} resample_scratch_t;

typedef struct {
    uint particle_count;
    uint observation_count;
    model_t model;
} uniforms_t;

#endif // #ifndef particle_filter_h
