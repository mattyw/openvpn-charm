ifndef UNIT
	UNIT := `juju status --format json | jq -r '.applications["openvpn"].units|keys|.[]' | head -1`
endif
ifndef CLIENT
	CLIENT := $(shell hostname)
endif

.PHONY: all
all: build

.PHONY: build
build:
	charm build -l debug

.PHONY: clean
clean:
	$(RM) -r builds deps *.ovpn

.PHONY: deploy
deploy: build
	juju deploy $(shell pwd)/builds/openvpn openvpn

.PHONY: upgrade
upgrade: build
	juju upgrade-charm --path $(shell pwd)/builds/openvpn openvpn --force-units
	juju resolved $(UNIT)

.PHONY: client-ovpn
ovpn: $(CLIENT).ovpn
	-echo OpenVPN client created: $<

.PHONY: nm-import
nm-import: $(CLIENT).ovpn
	nmcli con import type openvpn file $<

$(CLIENT).ovpn:
	(juju run --unit $(UNIT) "actions/client $(CLIENT)" > $@) || ($(RM) -f $@; false)
