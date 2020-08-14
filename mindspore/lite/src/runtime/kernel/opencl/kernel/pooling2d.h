/**
 * Copyright 2020 Huawei Technologies Co., Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MINDSPORE_LITE_SRC_BACKEND_OPENCL_POOLING_H_
#define MINDSPORE_LITE_SRC_BACKEND_OPENCL_POOLING_H_

#include <vector>

#include "src/runtime/kernel/opencl/opencl_kernel.h"
#include "src/runtime/kernel/arm/nnacl/fp32/pooling.h"
#include "src/runtime/opencl/opencl_runtime.h"

namespace mindspore::kernel {

class PoolingOpenCLKernel : public OpenCLKernel {
 public:
  explicit PoolingOpenCLKernel(OpParameter *parameter, const std::vector<lite::tensor::Tensor *> &inputs,
                               const std::vector<lite::tensor::Tensor *> &outputs)
      : OpenCLKernel(parameter, inputs, outputs) {
    parameter_ = reinterpret_cast<PoolingParameter *>(parameter);
  }
  ~PoolingOpenCLKernel() override{};

  int Init() override;
  int ReSize() override;
  int Run() override;
  int InitBuffer();
  int GetImageSize(size_t idx, std::vector<size_t> *img_size) override;

 private:
  std::vector<size_t> InitGlobalSize() const;
  enum class MEM_TYPE { BUF, IMG } mem_type_{MEM_TYPE::IMG};
  PoolingParameter *parameter_;
  cl::Kernel kernel_;
};

}  // namespace mindspore::kernel

#endif  // MINDSPORE_LITE_SRC_BACKEND_OPENCL_POOLING_H_