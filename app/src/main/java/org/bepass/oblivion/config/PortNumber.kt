package org.bepass.oblivion.config

class PortNumber(val value: String) {
    init {
        require(value.toInt() in 0..65535)
    }
}