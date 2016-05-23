#!/usr/bin/env bash

set -e

docker-machine create -d scaleway         \
--scaleway-token=624f3764-fbd4-4677-8ae4-5750ccce37af \
--scaleway-organization=16fdd6a4-7492-4d18-a334-51eaf17a4f7d \
proxy

export DOCKER_IP=$(docker-machine ip proxy)
export CONSUL_SERVER_IP=$(docker-machine ip proxy)
export CONSUL_IP=$(docker-machine ip proxy)

eval "$(docker-machine env proxy)"

docker-compose up -d consul-server

sleep 2

docker-compose up -d proxy

docker-machine create -d scaleway \
	--scaleway-token=624f3764-fbd4-4677-8ae4-5750ccce37af \
	--scaleway-organization=16fdd6a4-7492-4d18-a334-51eaf17a4f7d \
    	--swarm --swarm-master \
    	--swarm-discovery="consul://$CONSUL_IP:8500" \
    	--engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    	--engine-opt="cluster-advertise=eth0:2376" \
    	swarm-master

docker-machine create -d scaleway \
	--scaleway-token=624f3764-fbd4-4677-8ae4-5750ccce37af \
        --scaleway-organization=16fdd6a4-7492-4d18-a334-51eaf17a4f7d \
    	--swarm \
    	--swarm-discovery="consul://$CONSUL_IP:8500" \
    	--engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    	--engine-opt="cluster-advertise=eth0:2376" \
    	swarm-node-1

docker-machine create -d scaleway \
        --scaleway-token=624f3764-fbd4-4677-8ae4-5750ccce37af \
        --scaleway-organization=16fdd6a4-7492-4d18-a334-51eaf17a4f7d \
        --swarm \
	--swarm-discovery="consul://$CONSUL_IP:8500" \
	--engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
	--engine-opt="cluster-advertise=eth0:2376" \
   	 swarm-node-2

eval "$(docker-machine env swarm-master)"

export DOCKER_IP=$(docker-machine ip swarm-master)

docker-compose up -d registrator

eval "$(docker-machine env swarm-node-1)"

export DOCKER_IP=$(docker-machine ip swarm-node-1)

docker-compose up -d registrator

eval "$(docker-machine env swarm-node-2)"

export DOCKER_IP=$(docker-machine ip swarm-node-2)

docker-compose up -d registrator
