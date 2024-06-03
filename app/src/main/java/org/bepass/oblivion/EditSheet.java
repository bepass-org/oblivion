package org.bepass.oblivion;

import android.content.Context;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.google.android.material.bottomsheet.BottomSheetDialog;

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

        this.title = context.getString(R.string.editSheetEndpoint, title); // context.getString(R.string.editSheetEndpoint, title
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

    public void start() {
        if (isElementsNull()) {
            return;
        }

        titleView.setText(title);
        value.setText(fileManager.getString("USERSETTING_" + sharedPrefKey));

        cancel.setOnClickListener(v -> sheet.cancel());
        apply.setOnClickListener(v -> {
            fileManager.set("USERSETTING_" + sharedPrefKey, value.getText().toString());
            sheet.cancel();
        });

        sheet.show();
        value.requestFocus();
        sheet.setOnCancelListener(dialog -> sheetsCallBack.onSheetClosed());
    }
}
