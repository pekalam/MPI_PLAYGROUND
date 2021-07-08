#include <mpi.h>
#include <stdio.h>
#include <iostream>

const int ACC = 10;
const int PER_WORKER = 4;

int main(int argc, char **argv)
{
    MPI_Init(NULL, NULL);

    int world_size;
    MPI_Comm_size( MPI_COMM_WORLD, &world_size );

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    float local = 0.0f;
    float global = 0.0f;
    float pi = 0.0f;
    int start = 1;

    int i = 0;
    while (i++ < ACC)
    {
        if(world_rank == 0){
            MPI_Bcast(&start, 1, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Barrier(MPI_COMM_WORLD);

            start += world_size*PER_WORKER*2;

            MPI_Reduce(&local, &global, 1, MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);
            pi += global;
        }
        else{
            MPI_Bcast(&start, 1, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Barrier(MPI_COMM_WORLD);

            int j = 1;
            start += (world_rank-1)*PER_WORKER*2;
            int end = start + (PER_WORKER-1)*2;
            //std::cout << "rank " << world_rank << " computing from start: " << start << std::endl;
    
            local=0.0f;
            for(int i = start; i <= end; i+=2){
                local += (j % 2 == 0 ? -1 : 1) * 1/(float)i;
                //std::cout << (j % 2 == 0 ? "-" : "") << "1/" << i << std::endl;
                j++;
            } 
            MPI_Reduce(&local, &global, 1, MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);
        }
    }


    if (world_rank == 0)
    {
        printf("PI=%.10f\n", pi*4.f);
    }

    MPI_Finalize();
}