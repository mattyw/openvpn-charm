PROJECT_ROOT := $(shell cd ..; pwd)

all: build

build:
	JUJU_REPOSITORY=$(PROJECT_ROOT) charm build -l debug


clean:
	$(RM) -r $(PROJECT_ROOT)/trusty/openvpn

deploy: build
	juju deploy $(PROJECT_ROOT)/trusty/openvpn openvpn --series trusty

upgrade: build
	juju upgrade-charm --path $(PROJECT_ROOT)/trusty/openvpn openvpn --force-units
	juju resolved openvpn/0

client:
	juju run --unit openvpn/0 "actions/client.sh"
	juju scp openvpn/0:/home/ubuntu/client1.tgz ./


.PHONY: all build clean deploy upgrade
