package org.bepass.oblivion.ui;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.BaseActivity;
import org.bepass.oblivion.databinding.ActivityLogBinding;

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
        setContentView(R.layout.activity_log);

        setupScrollListener();
        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

        binding.copytoclip.setOnClickListener(v -> copyLast100LinesToClipboard());

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
            e.printStackTrace();
        }
    }

    private void copyLast100LinesToClipboard() {
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

        String last100Log = sb.toString();
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("Log", last100Log);
        clipboard.setPrimaryClip(clip);
    }
}
