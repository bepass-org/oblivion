package org.bepass.oblivion.base;

import android.os.Build;
import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;

import org.bepass.oblivion.utils.ColorUtils;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.SystemUtils;

/**
 * BaseActivity is an abstract class serving as a base for activities in an Android application.
 * It extends the AppCompatActivity class and utilizes Android's data binding framework.
 * @param <B> The type of ViewDataBinding associated with the activity.
 */
public abstract class BaseActivity<B extends ViewDataBinding> extends AppCompatActivity {

    // ViewDataBinding instance associated with the activity layout
    protected B binding;

    // Tag for logging purposes
    protected String TAG = this.getClass().getSimpleName();

    /**
     * Abstract method to be implemented by subclasses to provide the layout resource ID for the activity.
     * @return The layout resource ID.
     */
    protected abstract int getLayoutResourceId();

    protected abstract int getStatusBarColor();

    /**
     * Called when the activity is starting.
     * @param savedInstanceState If the activity is being re-initialized after previously being shut down then this Bundle contains the data it most recently supplied in onSaveInstanceState(Bundle).
     * @see AppCompatActivity#onCreate(Bundle)
     */
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FileManager.initialize(this); // Initialize FileManager with Activity context
        // Inflates the layout and initializes the binding object
        binding = DataBindingUtil.setContentView(this, getLayoutResourceId());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            SystemUtils.setStatusBarColor(
                    this, getStatusBarColor(), ColorUtils.isColorDark(getStatusBarColor())
            );
        }
    }
}