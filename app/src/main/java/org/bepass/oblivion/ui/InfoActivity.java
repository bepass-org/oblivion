    package org.bepass.oblivion.ui;

    import android.content.Intent;
    import android.net.Uri;
    import android.os.Bundle;

    import org.bepass.oblivion.R;
    import org.bepass.oblivion.base.BaseActivity;
    import org.bepass.oblivion.databinding.ActivityInfoBinding;
    import org.bepass.oblivion.utils.ThemeHelper;

    public class InfoActivity extends BaseActivity<ActivityInfoBinding> {

        @Override
        protected int getLayoutResourceId() {
            return R.layout.activity_info;
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

            binding.githubLayout.setOnClickListener(v -> {
                Uri uri = Uri.parse("https://github.com/bepass-org/oblivion");
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                startActivity(intent);
            });

            binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        }
    }
