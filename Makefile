UNIT=openvpn/0  # TODO: get actual unit with juju status & jq

.PHONY: all
all: build

.PHONY: build
build:
	charm build -l debug

.PHONY: clean
clean:
	$(RM) -r builds deps

.PHONY: deploy
deploy: build
	juju deploy $(shell pwd)/builds/openvpn openvpn

.PHONY: upgrade
upgrade: build
	juju upgrade-charm --path $(shell pwd)/builds/openvpn openvpn --force-units
	juju resolved $(UNIT)

.PHONY: client
client:
	juju run --unit $(UNIT) "actions/client.sh clientb"
	juju scp $(UNIT):/home/ubuntu/clientb/clientb.tgz ./
