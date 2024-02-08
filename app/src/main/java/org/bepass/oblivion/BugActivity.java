
package org.bepass.oblivion;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import com.yoosef.oblivion.R;

import java.util.Timer;
import java.util.TimerTask;

public class BugActivity extends AppCompatActivity {
    FileManager fileManager;

    ImageView back;
    TextView logs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bug);

        fileManager = new FileManager(getApplicationContext());

        back = findViewById(R.id.back);
        logs = findViewById(R.id.logs);

        back.setOnClickListener(v -> onBackPressed());
        logs.setText(fileManager.getLog());

        // Update Log Every 1 Second
        new Timer().scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                logs.setText(fileManager.getLog());
            }
        }, 0, 1000);

    }

}