package org.bepass.oblivion;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

public class BugActivity extends AppCompatActivity {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private TextView logs;
    private ScrollView logScrollView;
    private boolean isUserScrollingUp = false;
    private Runnable logUpdater;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bug);

        ImageView back = findViewById(R.id.back);
        logs = findViewById(R.id.logs);
        logScrollView = findViewById(R.id.logScrollView);

        setupScrollListener();
        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        logUpdater = new Runnable() {
            @Override
            public void run() {
                readLogsFromFile();
                handler.postDelayed(this, 2000); // Refresh every 2 seconds
            }
        };
    }

    private void setupScrollListener() {
        logScrollView.getViewTreeObserver().addOnScrollChangedListener(() -> {
            int scrollY = logScrollView.getScrollY();
            int maxScrollY = logs.getHeight() - logScrollView.getHeight();
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
        new Thread(() -> {
            try (FileInputStream fis = openFileInput("logs.txt")) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
                StringBuilder sb = new StringBuilder();
                String line;

                while ((line = reader.readLine()) != null) {
                    sb.append(line).append("\n");
                }

                String finalLog = sb.toString();
                runOnUiThread(() -> {
                    logs.setText(finalLog);
                    if (!isUserScrollingUp) {
                        logScrollView.post(() -> logScrollView.fullScroll(ScrollView.FOCUS_DOWN));
                    }
                });
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();
    }
}
