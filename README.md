# REDIS CLUSTER FOR DOCKER

## How cluster for redis works

Please read [official documentation](https://redis.io/topics/cluster-tutorial) to understand how cluster should look like

## Run mode

You can set mode by 2 environment variables.

* `SENTINEL=1` - run container as a sentinel
* `MASTER=1`(work if `SENTINEL<>1`) - run application as a redis master

## ENV Variables

Check [Dockerfile](./Dockerfile) for more details. `ENV` directives will guide you.
