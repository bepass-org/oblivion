package org.bepass.oblivion.ui;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.BaseActivity;
import org.bepass.oblivion.databinding.ActivityLogBinding;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class LogActivity extends BaseActivity<ActivityLogBinding> {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean isUserScrollingUp = false;
    private Runnable logUpdater;

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_log;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        setupScrollListener();
        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        logUpdater = new Runnable() {
            @Override
            public void run() {
                readLogsFromFile();
                handler.postDelayed(this, 2000); // Refresh every 2 seconds
            }
        };
    }

    private void setupScrollListener() {
        binding.logScrollView.getViewTreeObserver().addOnScrollChangedListener(() -> {
            int scrollY = binding.logScrollView.getScrollY();
            int maxScrollY = binding.logs.getHeight() - binding.logScrollView.getHeight();
            isUserScrollingUp = scrollY < maxScrollY;
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        handler.post(logUpdater);
    }

    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(logUpdater);
    }

    private void readLogsFromFile() {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(openFileInput("logs.txt")))) {
            StringBuilder sb = new StringBuilder();
            String line;

            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }

            String finalLog = sb.toString();
            runOnUiThread(() -> {
                binding.logs.setText(finalLog);
                if (!isUserScrollingUp) {
                    binding.logScrollView.post(() -> binding.logScrollView.fullScroll(ScrollView.FOCUS_DOWN));
                }
            });
        } catch (IOException e) {
            Log.e(TAG, "readLogsFromFile: ",e );
        }
    }
}
