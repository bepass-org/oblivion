package org.bepass.oblivion.utils

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.LayoutInflater
import androidx.databinding.DataBindingUtil
import org.bepass.oblivion.R
import org.bepass.oblivion.databinding.DialogBatteryOptimizationBinding

/**
 * Checks if the app is running in restricted background mode.
 * Returns true if running in restricted mode, false otherwise.
 */
fun isBatteryOptimizationEnabled(context: Context): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return powerManager?.isIgnoringBatteryOptimizations(context.packageName) == false
    }
    return false
}

/**
 * Directly requests to ignore battery optimizations for the app.
 */
@SuppressLint("BatteryLife")
fun requestIgnoreBatteryOptimizations(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            // Check if context is an Activity
            if (context is Activity) {
                context.startActivityForResult(intent, 0) // Consider using a valid request code
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
        }
    }
}


/**
 * Shows a dialog explaining the need for disabling battery optimization and navigates to the app's settings.
 */
fun showBatteryOptimizationDialog(context: Context) {
    // Inflate the dialog layout using Data Binding
    val binding: DialogBatteryOptimizationBinding = DataBindingUtil.inflate(
        LayoutInflater.from(context),
        R.layout.dialog_battery_optimization,
        null,
        false
    )

    val dialog = AlertDialog.Builder(context)
        .setView(binding.root)
        .create()

    // Set dialog title and message
    binding.dialogTitle.text = context.getString(R.string.batteryOpL)
    binding.dialogMessage.text = context.getString(R.string.dialBtText)

    // Set positive button action
    binding.dialogButtonPositive.setOnClickListener {
        requestIgnoreBatteryOptimizations(context)
        dialog.dismiss()
    }

    // Set negative button action
    binding.dialogButtonNegative.setOnClickListener {
        dialog.dismiss()
    }

    dialog.show()
}
