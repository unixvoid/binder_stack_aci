OS_PERMS=sudo
BINDER_BIN=https://cryo.unixvoid.com/bin/binder/binder-latest-linux-amd64
ALPINE_FS=https://cryo.unixvoid.com/bin/filesystem/alpine/linux-latest-amd64.rootfs.tar.gz
REDIS_FS=https://cryo.unixvoid.com/bin/redis/filesystem/rootfs.tar.gz
REDIS_BIN=https://cryo.unixvoid.com/bin/redis/3.2.8/redis-server
NGINX_BIN=https://cryo.unixvoid.com/bin/nginx/fancy_index/nginx-1.11.10-linux-amd64

all: build_standalone_aci

prep_standalone_aci:
	cp -R deps/binder-layout .
	# alpine fs
	wget -O alpinefs.tar.gz $(ALPINE_FS)
	tar -xzf alpinefs.tar.gz -C binder-layout/rootfs/
	rm alpinefs.tar.gz
	# redis fs
	wget -O redisfs.tar.gz $(REDIS_FS)
	tar -xzf redisfs.tar.gz -C binder-layout/rootfs/
	rm redisfs.tar.gz
	# redis bin
	wget -O binder-layout/rootfs/bin/redis $(REDIS_BIN)
	chmod +x binder-layout/rootfs/bin/redis
	# nginx bin
	wget -O binder-layout/rootfs/bin/nginx $(NGINX_BIN)
	chmod +x binder-layout/rootfs/bin/nginx
	# add binder + misc files
	wget -O binder-layout/rootfs/bin/binder $(BINDER_BIN)
	chmod +x binder-layout/rootfs/bin/binder
	cp deps/config.gcfg binder-layout/rootfs/
	cp deps/redis.conf binder-layout/rootfs/
	cp deps/run.sh binder-layout/rootfs/
	#touch binder-layout/rootfs/nginx/log/error.log
	mkdir -p binder-layout/rootfs/uploads
	mkdir -p binder-layout/rootfs/nginx/log/
	mkdir -p binder-layout/rootfs/nginx/conf/
	mkdir -p binder-layout/rootfs/nginx/data/
	cp -R deps/nginx/nginx_fancyindex_data/* binder-layout/rootfs/nginx/data/
	cp deps/nginx/nginx.conf binder-layout/rootfs/nginx/conf/
	cp deps/nginx/mime.types binder-layout/rootfs/nginx/conf/
	cp deps/manifest.json binder-layout/manifest

build_standalone_aci: prep_standalone_aci
	# build image
	actool build binder-layout binder.aci
	@echo "binder.aci built"

build_travis_standalone_aci: prep_standalone_aci
	wget https://github.com/appc/spec/releases/download/v0.8.7/appc-v0.8.7.tar.gz
	tar -zxf appc-v0.8.7.tar.gz
	# build image
	appc-v0.8.7/actool build binder-layout binder.aci
	rm -rf appc-v0.8.7*
	@echo "binder.aci built"

test:
	mkdir -p test/binderdata
	mkdir -p test/redisdata
	$(OS_PERMS) rkt run \
		--net=host \
		--insecure-options=image \
        	--volume data,kind=host,source=$(shell pwd)/test/binderdata/ \
        	--volume redis,kind=host,source=$(shell pwd)/test/redisdata/ \
        	./binder.aci
clean:
	rm -rf binder-layout
	rm -f binder.aci
	rm -rf test/
