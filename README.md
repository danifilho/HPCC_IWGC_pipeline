# HPCC_IWGC_pipeline

To build the Dockerfile you need to run docker build --platform linux/amd64 -t maker:3.01.04 . and the executable of maker needs to be in the folder <br>
docker tag maker:3.01.04 danifilho/maker:3.01.04
docker push danifilho/maker:3.01.04 

docker pull danifilho/maker:3.01.04
singularity pull maker_3.01.04.sif docker://danifilho/maker:3.01.04
