package org.bepass.oblivion;

import android.content.Context;
import android.text.InputType;
import android.text.method.DigitsKeyListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.google.android.material.bottomsheet.BottomSheetDialog;

import java.util.Objects;

public class EditSheet {

    FileManager fileManager;

    Context context;
    BottomSheetDialog sheet;

    String title;
    String sharedPrefKey;

    TextView titleView;
    EditText value;
    Button apply, cancel;

    SheetsCallBack sheetsCallBack;

    public EditSheet(Context context, String title, String sharedPrefKey, SheetsCallBack sheetsCallBack) {
        this.context = context;
        fileManager = FileManager.getInstance(context);

        this.title = "تغییر مقدار " + title;
        this.sharedPrefKey = sharedPrefKey;

        this.sheetsCallBack = sheetsCallBack;

        init();
    }


    private void init() {
        // Initialize
        sheet = new BottomSheetDialog(context);
        sheet.setContentView(R.layout.edit_sheet);

        titleView = sheet.findViewById(R.id.title);
        value = sheet.findViewById(R.id.edittext);

        apply = sheet.findViewById(R.id.applyButton);
        cancel = sheet.findViewById(R.id.cancelButton);
    }

    public boolean isElementsNull() {
        return titleView == null || value == null || apply == null || cancel == null;
    }

    private boolean validatePort(String portStr) {
        int port = Integer.parseInt(portStr);
        return port >= 1024 && port <= 65535;
    }

    public void start() {
        if (isElementsNull()) {
            return;
        }

        if(Objects.equals(sharedPrefKey, "port")) {
            value.setInputType(InputType.TYPE_CLASS_NUMBER);
            value.setKeyListener(DigitsKeyListener.getInstance());
        }

        titleView.setText(title);
        value.setText(fileManager.getString("USERSETTING_" + sharedPrefKey));

        cancel.setOnClickListener(v -> sheet.cancel());
        apply.setOnClickListener(v -> {

            String input = value.getText().toString();

            if(input.equals("") && !Objects.equals(sharedPrefKey, "license")) {
                return;
            }

            boolean isPort = Objects.equals(sharedPrefKey, "port");
            boolean isValidPort = !isPort || validatePort(input);
            if(!isValidPort) {
                return;
            }

            String prefKey = "USERSETTING_" + sharedPrefKey;
            fileManager.set(prefKey, input);
            sheet.cancel();

        });

        sheet.show();
        value.requestFocus();
        sheet.setOnCancelListener(dialog -> sheetsCallBack.onSheetClosed());
    }


}
