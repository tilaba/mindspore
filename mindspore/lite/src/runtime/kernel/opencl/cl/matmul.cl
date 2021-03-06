#pragma OPENCL EXTENSION cl_khr_fp16 : enable
#define C4NUM 4
#define UP_DIV(x, y) (((x) + (y) - (1)) / (y))
__constant sampler_t smp_zero = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;
__kernel void MatMul_NHWC4_2d(__read_only image2d_t input, __global FLT16 *weight, __read_only image2d_t bias,
                              __write_only image2d_t output, int4 in_shape, int4 out_shape, int has_bias) {
  int gidx = get_global_id(0);  // CO4
  int gidz = get_global_id(2);  // N
  int lidx = get_local_id(0);
  int lidy = get_local_id(1);
  int ci4 = UP_DIV(in_shape.w, C4NUM);
  int co4 = UP_DIV(out_shape.w, C4NUM);
  int n = out_shape.z;
  bool inside = gidx < co4 && gidz < n;
  FLT4 result = (FLT4)(0.0f);
  for (uint i = lidy; i < ci4 && inside; i += 4) {
    FLT4 v = READ_IMAGE(input, smp_zero, (int2)(i, gidz));
    FLT16 w = weight[i * co4 + gidx];
    result.x += dot(v, w.s0123);
    result.y += dot(v, w.s4567);
    result.z += dot(v, w.s89ab);
    result.w += dot(v, w.scdef);
  }
  WRITE_IMAGE(output, (int2)(gidx, gidz), result);
  __local FLT4 temp[32][4];
  temp[lidx][lidy] = result;
  barrier(CLK_LOCAL_MEM_FENCE);
  if (lidy == 0 && inside) {
    result += temp[lidx][1];
    result += temp[lidx][2];
    result += temp[lidx][3];
    if (has_bias != 0) {
      result += READ_IMAGE(bias, smp_zero, (int2)(gidx, 0));
    }
    WRITE_IMAGE(output, (int2)(gidx, gidz), result);
  }
}

__kernel void MatMul_NC4HW4_2d(__read_only image2d_t input, __global FLT16 *weight, __read_only image2d_t bias,
                               __write_only image2d_t output, int4 in_shape, int4 out_shape, int has_bias) {
  int gidx = get_global_id(0);  // CO4
  int gidz = get_global_id(2);  // N
  int lidx = get_local_id(0);
  int lidy = get_local_id(1);
  int ci4 = UP_DIV(in_shape.w, C4NUM);
  int co4 = UP_DIV(out_shape.w, C4NUM);
  int n = out_shape.z;
  bool inside = gidx < co4 && gidz < n;
  FLT4 result = (FLT4)(0.0f);
  for (uint i = lidy; i < ci4 && inside; i += 4) {
    FLT4 v = READ_IMAGE(input, smp_zero, (int2)(gidz * ci4 + i, 0));
    FLT16 w = weight[i * co4 + gidx];
    result.x += dot(v, w.s0123);
    result.y += dot(v, w.s4567);
    result.z += dot(v, w.s89ab);
    result.w += dot(v, w.scdef);
  }
  __local FLT4 temp[32][4];
  temp[lidx][lidy] = result;
  barrier(CLK_LOCAL_MEM_FENCE);
  if (lidy == 0 && inside) {
    result += temp[lidx][1];
    result += temp[lidx][2];
    result += temp[lidx][3];
    if (has_bias != 0) {
      result += READ_IMAGE(bias, smp_zero, (int2)(gidx, 0));
    }
    WRITE_IMAGE(output, (int2)(gidz * co4 + gidx, 0), result);
  }
}

__kernel void MatMul_NHWC4_4d(__read_only image2d_t input, __global FLT16 *weight, __read_only image2d_t bias,
                              __write_only image2d_t output, int4 in_shape, int4 out_shape, int has_bias) {
  int gidx = get_global_id(0);  // CO4
  int gidy = get_global_id(1);  // N * H * 4
  int gidz = get_global_id(2);  // W
  int lidx = get_local_id(0);
  int lidy = get_local_id(1);
  int ci4 = UP_DIV(in_shape.w, C4NUM);
  int co4 = UP_DIV(out_shape.w, C4NUM);
  int n = out_shape.x;
  int h = out_shape.y;
  int w = out_shape.z;
  int nh_index = gidy / 4;
  bool inside = gidx < co4 && gidz < w && nh_index < n * h;
  FLT4 result = (FLT4)(0.0f);
  for (uint i = lidy; i < ci4 && inside; i += 4) {
    FLT4 v = READ_IMAGE(input, smp_zero, (int2)(gidz * ci4 + i, nh_index));
    FLT16 weight_value = weight[nh_index * ci4 * co4 + i * co4 + gidx];
    result.x += dot(v, weight_value.s0123);
    result.y += dot(v, weight_value.s4567);
    result.z += dot(v, weight_value.s89ab);
    result.w += dot(v, weight_value.scdef);
  }
  __local FLT4 temp[32][4];
  temp[lidx][lidy] = result;
  barrier(CLK_LOCAL_MEM_FENCE);
  if (lidy == 0 && inside) {
    result += temp[lidx][1];
    result += temp[lidx][2];
    result += temp[lidx][3];
    if (has_bias != 0) {
      result += READ_IMAGE(bias, smp_zero, (int2)(gidx, 0));
    }
    WRITE_IMAGE(output, (int2)(gidz * co4 + gidx, nh_index), result);
  }
}

__kernel void MatMul_NC4HW4_4d(__read_only image2d_t input, __global FLT16 *weight, __read_only image2d_t bias,
                               __write_only image2d_t output, int4 in_shape, int4 out_shape, int has_bias) {
  int gidx = get_global_id(0);  // CO4
  int gidy = get_global_id(1);  // N * H * 4
  int gidz = get_global_id(2);  // W
  int lidx = get_local_id(0);
  int lidy = get_local_id(1);
  int ci4 = UP_DIV(in_shape.w, C4NUM);
  int co4 = UP_DIV(out_shape.w, C4NUM);
  int n = out_shape.x;
  int h = out_shape.y;
  int w = out_shape.z;
  int nh_index = gidy / 4;
  bool inside = gidx < co4 && gidz < w && nh_index < n * h;
  int n_index = nh_index / h;
  int h_index = nh_index % h;
  FLT4 result = (FLT4)(0.0f);
  for (uint i = lidy; i < ci4 && inside; i += 4) {
    FLT4 v = READ_IMAGE(input, smp_zero, (int2)(gidz, n_index * ci4 * h + i * h + h_index));
    FLT16 weight_value = weight[nh_index * ci4 * co4 + i * co4 + gidx];
    result.x += dot(v, weight_value.s0123);
    result.y += dot(v, weight_value.s4567);
    result.z += dot(v, weight_value.s89ab);
    result.w += dot(v, weight_value.scdef);
  }
  __local FLT4 temp[32][4];
  temp[lidx][lidy] = result;
  barrier(CLK_LOCAL_MEM_FENCE);
  if (lidy == 0 && inside) {
    result += temp[lidx][1];
    result += temp[lidx][2];
    result += temp[lidx][3];
    if (has_bias != 0) {
      result += READ_IMAGE(bias, smp_zero, (int2)(gidx, 0));
    }
    WRITE_IMAGE(output, (int2)(gidz, n_index * co4 * h + gidx * h + h_index), result);
  }
}
