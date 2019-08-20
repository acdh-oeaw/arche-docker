# Simple Docker deployment of the ACDH repository

`docker build -t acdh-repo --force-rm .`
`docker run --name acdh-repo -d -p 80:80 --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH acdh-repo`
