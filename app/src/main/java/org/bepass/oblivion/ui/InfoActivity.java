package org.bepass.oblivion.ui;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import androidx.appcompat.app.AppCompatActivity;

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.BaseActivity;
import org.bepass.oblivion.databinding.ActivityInfoBinding;

public class InfoActivity extends BaseActivity<ActivityInfoBinding> {

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_info;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        binding.githubLayout.setOnClickListener(v -> {
            Uri uri = Uri.parse("https://github.com/bepass-org/oblivion");
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(intent);
        });

        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
    }
}
