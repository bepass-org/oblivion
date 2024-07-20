package org.bepass.oblivion.utils

import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

object ISPUtils {

    private const val API_URL = "http://ip-api.com/json"

    // Interface to handle ISP callback
    interface ISPCallback {
        fun onISPInfoReceived(isp: String)
        fun onError(e: Exception)
    }

    // Public function to fetch ISP info
    @JvmStatic
    fun fetchISPInfo(callback: ISPCallback) {
        Thread {
            var connection: HttpURLConnection? = null
            var reader: BufferedReader? = null
            try {
                val url = URL(API_URL)
                connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"

                if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                    reader = BufferedReader(InputStreamReader(connection.inputStream))
                    val result = StringBuilder()
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        result.append(line)
                    }
                    val jsonObject = JSONObject(result.toString())
                    val isp = jsonObject.optString("org", "Unknown ISP")
                    callback.onISPInfoReceived(isp)
                } else {
                    callback.onError(Exception("Failed to get response. Code: ${connection.responseCode}"))
                }
            } catch (e: Exception) {
                callback.onError(e)
            } finally {
                try {
                    reader?.close()
                    connection?.disconnect()
                } catch (e: Exception) {
                    callback.onError(e)
                }
            }
        }.start()
    }
}