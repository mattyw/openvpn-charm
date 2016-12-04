import ipaddress
import os
from subprocess import check_call, check_output

from charmhelpers.core import hookenv, host
from charmhelpers.core.templating import render
from charmhelpers.fetch import apt_install, apt_purge, apt_update
from charms.reactive import hook, when, when_not, set_state, remove_state


@when_not('openvpn.installed')
@when('apt.installed.openvpn')
def install_openvpn():
    # Enable IP forwarding
    with open("/proc/sys/net/ipv4/ip_forward", "w") as f:
        f.write("1")
    # Make it permanent
    check_call([
        'sed', '-i', '-e', 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/', '/etc/sysctl.conf'])

    # Enable openvpn systemd service
    check_call([
        'sed', '-i', '-e', 's/#AUTOSTART="all"/AUTOSTART="all"/', '/etc/default/openvpn'])

    # TODO: could open once we're ready to start the service
    # TODO: could make it configurable or support multiple ports to help clients bypass firewalls
    hookenv.open_port(1194, protocol="UDP")

    set_state('openvpn.installed')


@when('config.changed', 'apt.installed.python3-netifaces')
def config():
    config = hookenv.config()
    if config.changed('subnet'):
        # Change in subnet requires ufw reconfiguration
        remove_state('openvpn.ufw.ready')
    ip = ipaddress.ip_network(config.get('subnet'))
    _, addr = resolve_iface()
    render(
        source='server.conf',
        target='/etc/openvpn/server.conf',
        owner='root',
        perms=0o644,
        context={
            'local_addr': addr,
            'network': ip.network_address,
            'netmask': ip.netmask,
            'dns_servers': config.get('dns-servers').split(' '),
            'loglevel': config.get('loglevel'),
        })
    if host.service_running('openvpn'):
        host.service_restart('openvpn')


@when('apt.installed.ufw', 'apt.installed.python3-netifaces')
@when_not('openvpn.ufw.ready')
def setup_ufw():
    """setup_ufw configures iptables to masquerade traffic for VPN clients.
    UFW is used for convenience; changes will persist across reboots."""
    config = hookenv.config()

    # Undo prior edits to ufw rules
    rules = check_output(['awk', '-f', os.path.join(hookenv.charm_dir(), 'reset-ufw-rules.awk'),
        '/etc/ufw/before.rules'], universal_newlines=True)
    with open('/etc/ufw/before.rules', 'w') as f:
        f.write(rules)

    iface, _ = resolve_iface()

    check_call([
        'sed', '-i', '-e', 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/', '/etc/default/ufw'])
    check_call([
        'sed', '-i',
        r'1i# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to network interface\n\n-A POSTROUTING -s %s -o %s -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES\n' % (
            config.get('subnet'), iface),
        '/etc/ufw/before.rules'])
    check_call(['ufw', 'allow', 'ssh'])
    check_call(['ufw', 'allow', '1194/udp'])
    check_call(['ufw', '--force', 'enable'])

    set_state('openvpn.ufw.ready')


def resolve_iface():
    """resolve_iface returns the network interface name (like eth0)
    for the unit's public IP address."""
    import netifaces
    try_addrs = [hookenv.unit_public_ip(), hookenv.unit_private_ip()]
    for addr in try_addrs:
        for iface in netifaces.interfaces():
            for item in netifaces.ifaddresses(iface).get(netifaces.AF_INET, []):
                if item.get('addr') == addr:
                    return iface, addr
    hookenv.status_set('blocked', 'unrecognized network interface')
    raise Exception('unrecognized network interface')


@when('apt.installed.easy-rsa')
@when_not('openvpn.easy-rsa.ready')
def setup_easy_rsa():
    check_call([os.path.join(hookenv.charm_dir(), 'setup-easy-rsa.bash')])
    set_state('openvpn.easy-rsa.ready')


@when_not('openvpn.available')
@when('openvpn.easy-rsa.ready', 'openvpn.ufw.ready', 'openvpn.installed')
def start_openvpn():
    check_call(['systemctl', 'daemon-reload'])
    if host.service_running('openvpn'):
        host.service_restart('openvpn')
    else:
        host.service_start('openvpn')
    hookenv.status_set('active', 'OpenVPN ready')
    set_state('openvpn.available')
