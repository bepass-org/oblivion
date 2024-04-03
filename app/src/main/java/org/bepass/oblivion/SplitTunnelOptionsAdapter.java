package org.bepass.oblivion;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RadioButton;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.switchmaterial.SwitchMaterial;

public class SplitTunnelOptionsAdapter extends RecyclerView.Adapter<SplitTunnelOptionsAdapter.ViewHolder> {

    private final OnSettingsChanged settingsCallback;

    private FileManager fm;


    public SplitTunnelOptionsAdapter(Context context, OnSettingsChanged settingsCallback) {
        this.settingsCallback = settingsCallback;
        fm = FileManager.getInstance(context);
    }


    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.split_tunnel_options, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        SplitTunnelMode stm = SplitTunnelMode.getSplitTunnelMode(fm);
        switch (stm) {
            case DISABLED:
                holder.disabled.setChecked(true);
                break;
            case BLACKLIST:
                holder.blacklist.setChecked(true);
                break;
        }
        holder.showSystemApps.setOnCheckedChangeListener((buttonView, isChecked) -> settingsCallback.shouldShowSystemApps(isChecked));
        holder.disabled.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                settingsCallback.splitTunnelMode(SplitTunnelMode.DISABLED);
                fm.set("splitTunnelMode", SplitTunnelMode.DISABLED.toString());
            }
        });
        holder.blacklist.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                settingsCallback.splitTunnelMode(SplitTunnelMode.BLACKLIST);
                fm.set("splitTunnelMode", SplitTunnelMode.BLACKLIST.toString());
            }

        });
    }

    @Override
    public int getItemCount() {
        return 1; // Header has only one item
    }

    public interface OnSettingsChanged {
        void splitTunnelMode(SplitTunnelMode mode);

        void shouldShowSystemApps(boolean show);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        SwitchMaterial showSystemApps;
        RadioButton disabled;
        RadioButton blacklist;
        RadioButton whitelist;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            showSystemApps = itemView.findViewById(R.id.showSystemApps);
            disabled = itemView.findViewById(R.id.disabled);
            blacklist = itemView.findViewById(R.id.blacklist);
        }
    }
}