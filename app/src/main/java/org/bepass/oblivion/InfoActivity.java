package org.bepass.oblivion;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.yoosef.oblivion.R;

public class InfoActivity extends AppCompatActivity {

    ImageView back;
    RelativeLayout github, twitter, ircf;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_info);

        init();

        github.setOnClickListener(v -> openURL("https://github.com/bepass"));
        twitter.setOnClickListener(v -> openURL("https://x.com/uo0sef"));
        ircf.setOnClickListener(v -> openURL("https://ircf.space"));

        back.setOnClickListener(v -> onBackPressed());
    }

    private void init() {
        back = findViewById(R.id.back);
        github = findViewById(R.id.github_layout);
        twitter = findViewById(R.id.twitter_layout);
        ircf = findViewById(R.id.ircf_layout);
    }

    protected void openURL(String url) {
        Uri uri = Uri.parse(url);
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        startActivity(intent);
    }
}