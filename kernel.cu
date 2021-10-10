
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <ctime>
#include <math.h>
#include <stdio.h>
#include <iostream>
using namespace std;


#define N (100)
#define k (20)
const int threadsPerBlock = 1024;



 __global__ void sortKernel(int* dev_arr, int* helper)
    {
        int schet = 0;
        int powtor = 0;
        __shared__ int temp[1024];
        if (blockIdx.x * blockDim.x + threadIdx.x < N)
        {
            temp[threadIdx.x] = dev_arr[blockIdx.x * blockDim.x + threadIdx.x];
            for (int i = 0; i < N; ++i) {

                if (dev_arr[i] < temp[threadIdx.x])
                    ++schet; //позиция в результате

                if (dev_arr[i] == temp[threadIdx.x])
                    ++powtor; //позиция в результате
            }

            helper[dev_arr[blockIdx.x * blockDim.x + threadIdx.x]] = powtor;


            // dev_arr[schet] = temp[threadIdx.x];
        }
    

}


 __global__ void sortKernelFinal(int* dev_arr, int* helper)
 {
     

       int b = 0;
       for (int i = 0; i < k + 1; ++i) {
           for (int j = 0; j < helper[i]; ++j) {
               dev_arr[b++] = i;
           }
       }
      // __syncthreads();*/




 }
__global__ void get_arr(int* dev_arr) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int i = 0;
    
    if (idx < N) {
        if (idx < k-2)
        {

            if (idx % 2 == 0)
                dev_arr[idx] = idx;
            else
                dev_arr[idx] = idx + 2;
        } else
            dev_arr[idx] = idx % k;

        printf(" %d, ", dev_arr[idx]);
    }

 /*   if (idx < N) {
        dev_arr[idx] = N - idx;
        printf(" %d, ", dev_arr[idx]);
    }*/
    //

}

__global__ void get_arr_zero(int* dev_zero) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;


    if (idx < k) {   

        dev_zero[idx] = 0;
        
    }
    //printf(" %d, ", dev_zero[idx]);

}


__global__ void show_arr(int* dev_arr) {
    __syncthreads();
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    printf(" %d, ", dev_arr[idx]);

}

void get_array_for_CPU(int* mas) {
    for (int i = 0; i < N; i++) {
        mas[i] = rand() % k;;
    }
    for (int i = 0; i < N - 1; i++)
        printf(" %d, ", mas[i]);
    printf("\n");

}
void sort_for_CPU(int* mas, int* masHelper)
{
    for (int i = 0; i < N - 1; ++i) {
        ++masHelper[mas[i]];
    }

    int b = 0;
    for (int i = 0; i < k + 1; ++i) {
        for (int j = 0; j < masHelper[i]; ++j) {
            mas[b++] = i;
        }
    }
    printf("after sort \n");
    for (int i = 0; i < N-1; i++)
        printf(" %d, ", mas[i]);
    
}


int main() {
    //GPU
    int* host_arr = new int[N];
    int* dev_arr = new int[N];
  //  int* dev_res = new int[N];
    int* dev_help = new int[k];
    float elapsedTimeInMs = 0.0f;


    cudaDeviceReset();


    cudaMalloc((void**)&dev_arr, N * sizeof(int));
  //  cudaMalloc((void**)&dev_res, N * sizeof(int));
    cudaMalloc((void**)&dev_help, N * sizeof(int));

    get_arr << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr);
   // get_arr_zero << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_help);

   // printf(" -------------------------------------------- \n");
    //show_arr << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr);
    printf("\n");
    printf(" -------------------------------------------- \n");
    printf(" GPU \n");
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);
    cudaEventSynchronize(start);
    cudaThreadSynchronize();
    sortKernel << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr, dev_help);
    sortKernelFinal << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr, dev_help);
    cudaThreadSynchronize();
    cudaMemcpy(host_arr, dev_arr, N * sizeof(int), cudaMemcpyDeviceToHost);
    cudaThreadSynchronize();
    

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTimeInMs, start, stop);
    
    printf("  \n");
    printf(" -------------------------------------------- \n");
    for (int i = 0; i < N - 1; i++)
        printf(" %d, ", host_arr[i]);
    //for (int i = 0; i < N; i++)
      //  printf("=>%d", host_arr[i]);
    cudaFree(dev_arr);
    delete[]host_arr;

    printf("Time in GPU %f\n", elapsedTimeInMs / 1000);
   
    printf(" -------------------------------------------- \n");
    printf(" -------------------------------------------- \n");
    printf(" CPU \n");
    printf(" -------------------------------------------- \n");
    printf(" -------------------------------------------- \n");
    //CPU
    int* a = new int[N];
    int masHelper[k] = { 0 };
    clock_t start2;
    double time2;
    start2 = clock();
    
    get_array_for_CPU(a);

    
    sort_for_CPU(a, masHelper);
    
    time2 = (double)(clock() - start2) / CLOCKS_PER_SEC;
    printf("Time in CPU %f\n", time2);




    return 0;
}