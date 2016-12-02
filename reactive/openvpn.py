import os
import subprocess

from charmhelpers.core import hookenv
from charmhelpers.fetch import apt_install, apt_purge, apt_update
from charms.reactive import hook, when, when_not, set_state


@when_not('openvpn.installed')
def install_openvpn():
    apt_update()
    apt_install("easy-rsa")
    apt_install("openvpn")
    hookenv.log(hookenv.charm_dir())
    installer = os.path.join(hookenv.charm_dir(), "install.sh")
    subprocess.check_call([installer, hookenv.unit_public_ip()])
    hookenv.open_port(1194, protocol="UDP")
    set_state('openvpn.installed')


@hook('config-changed')
def config_changed():
    install_openvpn()
