package org.bepass.oblivion.utils

import android.annotation.SuppressLint
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.LayoutInflater
import android.widget.Button
import android.widget.TextView
import org.bepass.oblivion.R

/**
 * Checks if the app is running in restricted background mode.
 * Returns true if running in restricted mode, false otherwise.
 */
fun isBatteryOptimizationEnabled(context: Context): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        powerManager?.isIgnoringBatteryOptimizations(context.packageName) == false
    } else {
        false
    }
}

/**
 * Directly requests to ignore battery optimizations for the app.
 */
@SuppressLint("BatteryLife")
fun requestIgnoreBatteryOptimizations(context: Context) {
    val intent = Intent().apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            data = Uri.parse("package:${context.packageName}")
        }
    }
    context.startActivity(intent)
}


/**
 * Shows a dialog explaining the need for disabling battery optimization and navigates to the app's settings.
 */
fun showBatteryOptimizationDialog(context: Context) {
    val dialogView = LayoutInflater.from(context).inflate(R.layout.dialog_battery_optimization, null)

    val dialog = AlertDialog.Builder(context).apply {
        setView(dialogView)
    }.create()

    dialogView.findViewById<TextView>(R.id.dialog_title).text = context.getString(R.string.batteryOpL)
    dialogView.findViewById<TextView>(R.id.dialog_message).text = context.getString(R.string.dialBtText)

    dialogView.findViewById<Button>(R.id.dialog_button_positive).setOnClickListener {
        requestIgnoreBatteryOptimizations(context)
        dialog.dismiss()
    }

    dialogView.findViewById<Button>(R.id.dialog_button_negative).setOnClickListener {
        dialog.dismiss()
    }

    dialog.show()
}
