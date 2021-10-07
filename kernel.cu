
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <ctime>
#include <math.h>
#include <stdio.h>
#include <iostream>
using namespace std;


#define N (20000)
#define k (50)
const int threadsPerBlock = 1024;
//const int threads_qty = N / 2;



__global__ void sortKernel(int* dev_arr)
{
    int schet = 0;
    __shared__ int temp[1024];
    temp[threadIdx.x] = dev_arr[blockIdx.x * blockDim.x + threadIdx.x];
    for (int i = 0; i < N; ++i) {
        if (dev_arr[i] < temp[threadIdx.x])
            ++schet; //позиция в результате
    }

    __syncthreads();
    dev_arr[schet] = temp[threadIdx.x];

}
__global__ void get_arr(int* dev_arr) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        if (idx % 2 == 0)
            dev_arr[idx] = idx;
        else
            dev_arr[idx] = idx + 9;
    }
}


void get_array_for_CPU(int* arr) {
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % k;;
    }
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
}


int main() {
    //GPU
    int* host_arr = new int[N];
    int* dev_arr = new int[N];

    float elapsedTimeInMs = 0.0f;


    cudaDeviceReset();


    cudaMalloc((void**)&dev_arr, N * sizeof(int));

    get_arr << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr);
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);
    cudaEventSynchronize(start);
    cudaThreadSynchronize();
    sortKernel << <dim3(((N + 511) / 512), 1), dim3(threadsPerBlock, 1) >> > (dev_arr);
    cudaThreadSynchronize();
    cudaMemcpy(host_arr, dev_arr, N * sizeof(int), cudaMemcpyDeviceToHost);
    cudaThreadSynchronize();
//for (int i = 0; i < N; i++)
  //      printf(host_arr[i]);

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTimeInMs, start, stop);
    printf("Time in GPU %f\n", elapsedTimeInMs / 1000);
    

    cudaFree(dev_arr);
    delete[]host_arr;

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