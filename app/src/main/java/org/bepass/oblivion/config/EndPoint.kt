package org.bepass.oblivion.config

class EndPoint(val value: String) {
    init {
        require(!value.startsWith("http") && value.contains(":"))
    }
}