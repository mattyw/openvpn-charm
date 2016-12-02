PROJECT_ROOT := $(shell cd ..; pwd)
UNIT=openvpn/0

all: build

build:
	JUJU_REPOSITORY=$(PROJECT_ROOT) charm build -l debug


clean:
	$(RM) -r $(PROJECT_ROOT)/trusty/openvpn

deploy: build
	juju deploy $(PROJECT_ROOT)/trusty/openvpn openvpn --series trusty

upgrade: build
	juju upgrade-charm --path $(PROJECT_ROOT)/trusty/openvpn openvpn --force-units
	juju resolved $(UNIT)

client:
	juju run --unit $(UNIT) "actions/client.sh clientb"
	juju scp $(UNIT):/home/ubuntu/clientb/clientb.tgz ./


.PHONY: all build clean deploy upgrade
