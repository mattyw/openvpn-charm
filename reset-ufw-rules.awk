/[#] START OPENVPN RULES/ { inBlock = 1 }
inBlock {
    if ( /[#] END OPENVPN RULES/ ) {
        inBlock = 0
    }
    next
}
{ print }
