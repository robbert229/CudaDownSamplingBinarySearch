#include <stdio.h>
#include <stdlib.h>

#define ARRAY_LENGTH (100)
#define ARRAY_ELEMENT_SIZE (sizeof(long))
#define ARRAY_SIZE (ARRAY_ELEMENT_SIZE * ARRAY_LENGTH)
#define SAMPLE_LENGTH (5)
#define SAMPLE_SIZE (ARRAY_ELEMENT_SIZE * SAMPLE_LENGTH)

/*
First create a downsampled array (create an array and populate it with every Nth element from array)
Search the downsampled array for the number closest but smaller than desired. Then look in the area between that number and next number in the sample
*/

void populateArray(long* array, long i){
	*(array + (i * sizeof(long)) ) = i;
	printf("long i = %ld\n",i);
}

void populateSample(long* array, long *sample,long index){
	*(sample + index) = *(array + (index * ARRAY_LENGTH / SAMPLE_LENGTH * sizeof(long)) );
}

long binary_search_guess(long *array, long number_of_elements, long key)
{
	long low = 0, high = number_of_elements-1, mid;
	while(low <= high)
	{
		mid = (low + high)/2;
		if(*(array + mid * sizeof(long)) < key)
		{
			low = mid + 1; 
		}
		else if(*(array + mid * sizeof(long)) == key)
		{
			return mid;
		}
		else if(*(array + mid * sizeof(long)) > key)
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

long binary_search_precise(long *array, long key,long low, long high)
{
	long mid;
	while(low <= high)
	{
		mid = (low + high)/2;
		if(*(array + mid * sizeof(long)) < key)
		{
			low = mid + 1; 
		}
		else if(*(array + mid * sizeof(long)) == key)
		{
			return mid;
		}
		else if(*(array + mid * sizeof(long)) > key)
		{
			high = mid-1;
		}
	}

	return -1;
}

int main(int argc,char* argv[]){
	long *array = malloc(ARRAY_SIZE);
	long *sample = malloc(SAMPLE_SIZE);
	printf("Populating Array\n");
	for(long i=0;i<ARRAY_LENGTH;i++)
		populateArray(array,i);

	printf("Populating Sample\n");
	for(long i=0;i<SAMPLE_LENGTH;i++)
		populateSample(array,sample,i);

	long target = atol(argv[1]);
	
	if(target < *array || target > *(array + ARRAY_SIZE - sizeof(long))){
		printf("Target out of bounds\n");
		return -1;
	}

	long guess = binary_search_guess(sample,SAMPLE_LENGTH,target);
	printf("guess == %ld\ntarget == %ld\n,sample[secondtolast] == %ld\n",guess,target,sample[SAMPLE_LENGTH-1]);
	printf("Heuristic Opinion: %ld is in range[%ld,%ld]\n",target,sample[guess],((target < sample[SAMPLE_LENGTH-1])?sample[guess+1]:ARRAY_LENGTH));
	long min = guess * ARRAY_LENGTH / SAMPLE_LENGTH;
	long max = (guess + 1) * ARRAY_LENGTH / SAMPLE_LENGTH;
	long actuall = binary_search_precise(array,target,min,max);
	printf("Actuality: %ld is in array[%ld]\n",target,actuall);

	FILE* fout = fopen("array.dat","w");
	for(int i=0;i<ARRAY_LENGTH;i++)
		fprintf(fout,"%ld\n",(long)*(array + i * sizeof(long)));
	fclose(fout);


	free(array);
	free(sample);
	return 0;
}