
# Pre-reqisites:
#     cabal-install-1.24
#     g++
#     gcc
#     ghc-8.0
#     liblzma-dev
#     librocksdb-dev
#     libsnappy-dev
#     libssl-dev
#     make

DATE = $(shell date)
PWD := $(shell pwd)

export HOME = $(PWD)/home

# Want the local path to come before global paths.
export PATH := $(PWD)/tools/bin:/usr/bin:/bin

export MAFIA_PATH := $(PWD)/mafia

TOOLS = tools/bin/jenga tools/bin/mafia


results/Daedalus-linux-x64/LICENSE : source/daedalus/release/linux-x64/Daedalus-linux-x64/LICENSE
	cp -r source/daedalus/release/linux-x64/Daedalus-linux-x64 $(shell dirname $@)

source/daedalus//release/linux-x64/Daedalus-linux-x64/LICENSE : source/daedalus/node_modules/tar/LICENSE
	(cd source/daedalus && npm run package -- --icon $(PWD)/results/Resources/icons/256x256.png)

source/daedalus/node_modules/tar/LICENSE : tools/bin/pkg source/daedalus/LICENSE
	(cd source/daedalus && npm install)

source/daedalus/LICENSE :
	@if test -d source/daedalus ; then \
		(cd source/daedalus && git pull) ; \
	else \
	    git clone https://github.com/input-output-hk/daedalus source/daedalus ; \
	    fi
	touch $@

#-------------------------------------------------------------------------------
# Auxillary files.

results/log-config-prod.yaml : source/cardano-sl/stack.yaml
	cp -f source/cardano-sl/log-config-prod.yaml $@

results/mainnet-genesis-dryrun-with-stakeholders.json : source/cardano-sl/stack.yaml
	cp -f source/cardano-sl/lib/mainnet-genesis-dryrun-with-stakeholders.json $@

results/mainnet-genesis.json : source/cardano-sl/stack.yaml
	cp -f source/cardano-sl/lib/mainnet-genesis.json $@

results/mainnet-staging-short-epoch-genesis.json : source/cardano-sl/stack.yaml
	cp -f source/cardano-sl/lib/mainnet-staging-short-epoch-genesis.json $@

results/configuration.yaml : source/cardano-sl/stack.yaml
	cp -f source/cardano-sl/lib/configuration.yaml $@

#-------------------------------------------------------------------------------
# Build cardano-launcher and cardano-node

results/cardano-launcher : source/cardano-sl/.jenga $(TOOLS)
	mkdir -p results
	(cd source/cardano-sl/tools && mafia build cardano-launcher)
	cp -f source/cardano-sl/tools/dist/build/cardano-launcher/cardano-launcher $@

results/cardano-node : source/cardano-sl/.jenga $(TOOLS)
	mkdir -p results
	(cd source/cardano-sl/wallet && mafia build cardano-node)
	cp -f source/cardano-sl/wallet/dist/build/cardano-node/cardano-node $@

source/cardano-sl/.jenga : source/cardano-sl/stack.yaml $(TOOLS)
	@if test -f $@ ; then \
		(cd source/cardano-sl/ && git pull --rebase && jenga update) ; \
	else \
		(cd source/cardano-sl/ && git pull --rebase && jenga init -m submods -d directory) ; \
		fi
	(cd source/cardano-sl/ && git reset origin/develop)
	(cd source/cardano-sl/ && git add .gitmodules && git commit -m "Add submodules" -- . )
	touch $@

source/cardano-sl/stack.yaml : $(TOOLS)
	@if test -d source/cardano-sl ; then \
		(cd source/cardano-sl && git pull) ; \
	else \
	    git clone https://github.com/input-output-hk/cardano-sl.git source/cardano-sl ; \
	    fi
	(cd source/cardano-sl/ && git checkout develop)
	touch $@

#-------------------------------------------------------------------------------
# Install node and npm (included with node) in order to build Daedalus.

tools/bin/pkg : tools/bin/node
	npm install -g pkg
	touch $@

tools/bin/node : stamp/check-tarball
	(cd source && tar xf $(PWD)/tarballs/node-v6.11.5.tar.gz)
	(cd source/node-v6.11.5 && ./configure --prefix=$(PWD)/tools && make install)
	touch $@

stamp/check-tarball : tarballs/node-v6.11.5.tar.gz
	sha256sum --check tarballs/sha256sum
	touch $@

tarballs/node-v6.11.5.tar.gz :
	mkdir -p tarballs
	curl -o $@ https://nodejs.org/dist/v6.11.5/node-v6.11.5.tar.gz

# ------------------------------------------------------------------------------
# Install Haskell tools mafia and jenga from source.

tools/bin/jenga : tools/bin/mafia
	@if test -d source/jenga ; then \
		(cd source/jenga && git pull) ; \
	else \
	    git clone https://github.com/erikd/jenga source/jenga ; \
	    fi
	(cd source/jenga && mafia build)
	cp -f source/jenga/dist/build/jenga/jenga $@

tools/bin/mafia :
	mkdir -p bin
	@if test -d source/mafia ; then \
		(cd source/mafia && git pull) ; \
	else \
	    git clone https://github.com/haskell-mafia/mafia source/mafia ; \
	    fi
	(cd source/mafia && script/mafia build)
	cp -f source/mafia/dist/build/mafia/mafia $@