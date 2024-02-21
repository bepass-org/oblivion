package org.bepass.oblivion;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.AttributeSet;

import com.suke.widget.SwitchButton;

public class TouchAwareSwitch extends SwitchButton {

    public TouchAwareSwitch(Context context) {
        super(context);
    }

    public TouchAwareSwitch(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public TouchAwareSwitch(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void setOnCheckedChangeListener(final OnCheckedChangeListener listener) {
        setOnTouchListener((v, event) -> {
            setTag(null);
            return false;
        });

        super.setOnCheckedChangeListener((view, isChecked) -> {
            if (getTag() != null) {
                setTag(null);
                return;
            }
            listener.onCheckedChanged(view, isChecked);
        });
    }

    public void setChecked(boolean checked, boolean notify) {
        if (!notify) setTag("TAG");
        setChecked(checked);
    }


}
