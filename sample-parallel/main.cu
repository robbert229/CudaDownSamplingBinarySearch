#include <stdlib.h>
#include <stdio.h>

#define ARRAY_LENGTH (100000)
#define ARRAY_ELEMENT_SIZE (sizeof(long))
#define ARRAY_SIZE (ARRAY_ELEMENT_SIZE * ARRAY_LENGTH)
#define SAMPLE_LENGTH (100)
#define SAMPLE_SIZE (ARRAY_ELEMENT_SIZE * SAMPLE_LENGTH)
#define QUERY_LENGTH (200)
#define QUERY_SIZE (ARRAY_ELEMENT_SIZE * QUERY_LENGTH)
#define PRINT_ARRAY (0)

/*
First create a downsampled array (create an array and populate it with every Nth element from array)
Search the downsampled array for the number closest but smaller than desired. Then look in the area between that number and next number in the sample
*/

int random(int min, int max){
	return (rand()%(max-min))+min;	
}

void populateArray(long* array, long i){
	array[i] = i;
	if(PRINT_ARRAY)
		printf("array[%ld] = %ld\n",i,array[i]);
}

__global__ void populateSample(long* array, long *sample){
	long i = threadIdx.x;
	sample[i] = array[i * ARRAY_LENGTH / SAMPLE_LENGTH];
}

void populateQuery(long* query, long i){
	query[i] = random(0,100);
	if(PRINT_ARRAY)
		printf("query[%ld] = %ld\n",i,query[i]);
}

__device__ long binary_search_guess(long *array, long number_of_elements, long key)
{
	long low = 0, high = number_of_elements-1, mid;
	while(low <= high)
	{
		mid = (low + high)/2;
		if(array[mid] < key)
		{
			low = mid + 1; 
		}
		else if(array[mid] == key)
		{
			return mid;
		}
		else if(array[mid] > key)
		{
			high = mid-1;
		}
	}

	if(array[mid] > key){
		while(mid > 0 && array[mid] > key){
			mid--;
		}
	}
	return mid;
}

__device__ long binary_search_precise(long *array, long key,long low, long high)
{
	long mid;
	while(low <= high)
	{
		mid = (low + high)/2;
		if(array[mid] < key)
		{
			low = mid + 1; 
		}
		else if(array[mid] == key)
		{
			return mid;
		}
		else if(array[mid] > key)
		{
			high = mid-1;
		}
	}
	return -1;
}


__global__ void search(long* array, long *sample, long*output, long* query){
	long index = threadIdx.x;
	if(query[index] < *array || query[index] >= sample[SAMPLE_LENGTH-1] + ARRAY_LENGTH / SAMPLE_LENGTH)
		output[index] = -1;
	
	long guess = binary_search_guess(sample,SAMPLE_LENGTH,query[index]);	
	output[index] = binary_search_precise(
		array,
		query[index],
		guess * ARRAY_LENGTH / SAMPLE_LENGTH,
		(guess + 1) * ARRAY_LENGTH / SAMPLE_LENGTH
	); 
}

int main(int argc,char* argv[]){
	long *array = (long*)malloc(ARRAY_SIZE);
	//long *sample = (long*)malloc(SAMPLE_SIZE);
	long *output = (long*)malloc(QUERY_SIZE);
	long *query = (long*)malloc(QUERY_SIZE);

	long *device_array;
	long *device_sample;
	long *device_output;
	long *device_query;

	cudaMalloc((void**)&device_array,ARRAY_SIZE);
	cudaMalloc((void**)&device_sample,SAMPLE_SIZE);
	cudaMalloc((void**)&device_output,QUERY_SIZE);
	cudaMalloc((void**)&device_query,QUERY_SIZE);

	// cpu
	printf("Populating Array\n");
	for(long i=0;i<ARRAY_LENGTH;i++)
		populateArray(array,i);

	// cpu
	printf("Populating Query\n");
	for(long i=0;i<QUERY_LENGTH;i++)
		populateQuery(query,i);

	// gpu
	printf("Populating Sample\n");
	populateSample<<<1,SAMPLE_LENGTH>>>(device_array,device_sample);

	cudaMemcpy(device_array,array,ARRAY_SIZE,cudaMemcpyHostToDevice);
	cudaMemcpy(device_query,query,QUERY_SIZE,cudaMemcpyHostToDevice);

	// gpu
	printf("Processing Query\n");
	search<<<1,QUERY_LENGTH>>>(device_array,device_sample,device_output,device_query);

	// copy the results from the gpu to the cpu
	cudaMemcpy(output,device_output,QUERY_SIZE,cudaMemcpyDeviceToHost);
	
	printf("Printing Results\n");
	for(long i=0;i<QUERY_LENGTH;i++)
		printf("results[%ld] = (%ld == [%ld])\n",i,output[i],query[i]);

	cudaFree(device_array);
	cudaFree(device_sample);
	cudaFree(device_output);
	cudaFree(device_query);

	free(array);
	free(output);
	free(query);

	return 0;
}