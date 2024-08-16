package org.bepass.oblivion.component;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.PorterDuff;
import android.net.Uri;
import android.util.AttributeSet;
import android.view.MotionEvent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatImageView;
import androidx.core.content.ContextCompat;

import org.bepass.oblivion.R;

import java.io.File;

public class Icon extends AppCompatImageView {
    private boolean hasBounceAnimation;
    private boolean isPrimaryIcon;

    public Icon(@NonNull Context context) {
        super(context);
        if (!isInEditMode())init();
    }

    public Icon(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        if (!isInEditMode()){
            setupAttrs(context, attrs, 0);
            init();
        }
    }

    public Icon(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        if (!isInEditMode()){
            setupAttrs(context, attrs, defStyleAttr);
            init();
        }
    }

    private void setupAttrs(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.Icon, defStyleAttr, 0);
        try {
            int color = a.getColor(R.styleable.Icon_icon_color, 0);
            if (color != 0) {
                setColorFilter(color, PorterDuff.Mode.SRC_ATOP);
            }
        }  finally {
            a.recycle();
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
//            if (hasBounceAnimation)
//                AnimationHelper.startPushButtonAnimation(this);
        }
        return super.onTouchEvent(event);

    }

    public void changeColor(int color) {
        if (color != 0) {
            setColorFilter(color, PorterDuff.Mode.SRC_ATOP);
        }
    }

    private void init() {
    }
}