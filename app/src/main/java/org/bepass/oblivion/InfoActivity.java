package org.bepass.oblivion;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import org.bepass.oblivion.R;

public class InfoActivity extends AppCompatActivity {

    ImageView back;
    RelativeLayout github;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_info);

        init();

        github.setOnClickListener(v -> openURL("https://github.com/bepass"));

        back.setOnClickListener(v -> onBackPressed());
    }

    private void init() {
        back = findViewById(R.id.back);
        github = findViewById(R.id.github_layout);
    }

    protected void openURL(String url) {
        Uri uri = Uri.parse(url);
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        startActivity(intent);
    }
}