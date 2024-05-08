package org.bepass.oblivion;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import androidx.appcompat.app.AppCompatActivity;

public class InfoActivity extends AppCompatActivity {

    ImageView back;
    RelativeLayout github;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_info);

        back = findViewById(R.id.back);
        github = findViewById(R.id.github_layout);

        github.setOnClickListener(v -> {
            Uri uri = Uri.parse("https://github.com/bepass-org/oblivion");
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(intent);
        });

        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
    }
}
