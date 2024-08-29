@file:JvmName("CountryCodeUtils")

package org.bepass.oblivion.utils

import java.util.Locale

fun CountryCode.toCountryFlagEmoji() = value.uppercase()
    .fold(charArrayOf()) { acc, c ->
        acc + Character.toChars(c.code + 0x1F1A5)
    }
    .joinToString(separator = "")

class CountryCode(val value: String) {
    init {
        require(value in Locale.getISOCountries())
    }
}
