package org.bepass.oblivion.ui;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.BaseActivity;
import org.bepass.oblivion.databinding.ActivityLogBinding;
import org.bepass.oblivion.utils.ISPUtils;
import org.bepass.oblivion.utils.ThemeHelper;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Deque;

public class LogActivity extends BaseActivity<ActivityLogBinding> {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean isUserScrollingUp = false;
    private Runnable logUpdater;
    private FrameLayout progressBar;

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_log;
    }

    @Override
    protected int getStatusBarColor() {
        return R.color.status_bar_color;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Update background based on current theme
        ThemeHelper.getInstance().updateActivityBackground(binding.getRoot());

        // Initialize the ProgressBar
        progressBar = findViewById(R.id.progress_container);
        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        binding.copytoclip.setOnClickListener(v -> copyLast100LinesToClipboard());
        setupScrollListener();

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
    private static final int MAX_LOG_LINES = 200; // Keep only last 200 lines in memory
    private final Deque<String> logBuffer = new ArrayDeque<>(MAX_LOG_LINES);

    private void readLogsFromFile() {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(openFileInput("logs.txt")))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (logBuffer.size() >= MAX_LOG_LINES) {
                    logBuffer.pollFirst(); // Remove the oldest line
                }
                logBuffer.addLast(line);
            }

            String finalLog = String.join("\n", logBuffer); // Efficient string concatenation

            runOnUiThread(() -> {
                if (!finalLog.equals(binding.logs.getText().toString())) { // Prevent unnecessary updates
                    binding.logs.setText(finalLog);
                }
                if (!isUserScrollingUp) {
                    binding.logScrollView.post(() -> binding.logScrollView.fullScroll(ScrollView.FOCUS_DOWN));
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private void copyLast100LinesToClipboard() {
        // Show progress bar
        progressBar.setVisibility(View.VISIBLE);

        ISPUtils.fetchISPInfo(new ISPUtils.ISPCallback() {
            @Override
            public void onISPInfoReceived(String isp) {
                runOnUiThread(() -> {
                    // Hide progress bar
                    progressBar.setVisibility(View.GONE);

                    String logText = binding.logs.getText().toString();
                    String[] logLines = logText.split("\n");
                    int totalLines = logLines.length;

                    // Use Deque to efficiently get the last 100 lines
                    Deque<String> last100Lines = new ArrayDeque<>(100);
                    last100Lines.addAll(Arrays.asList(logLines).subList(Math.max(0, totalLines - 100), totalLines));

                    StringBuilder sb = new StringBuilder();
                    for (String line : last100Lines) {
                        sb.append(line).append("\n");
                    }

                    // Add ISP information
                    sb.append("\n=====\nISP: ").append(isp).append("\n");

                    String last100Log = sb.toString();
                    ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                    ClipData clip = ClipData.newPlainText("Log", last100Log);
                    clipboard.setPrimaryClip(clip);

                    showCopiedToClipboardToast();
                });
            }

            @Override
            public void onError(Exception e) {
                runOnUiThread(() -> {
                    // Hide progress bar
                    progressBar.setVisibility(View.GONE);

                    e.printStackTrace();
                    Toast.makeText(LogActivity.this, "Error fetching ISP information.", Toast.LENGTH_SHORT).show();
                });
            }
        });
    }

    private void showCopiedToClipboardToast() {
        LayoutInflater inflater = getLayoutInflater();
        View layout = inflater.inflate(R.layout.toast, findViewById(R.id.toast_layout));

        Toast toast = new Toast(getApplicationContext());
        toast.setDuration(Toast.LENGTH_SHORT);
        toast.setView(layout);
        toast.show();
    }
}