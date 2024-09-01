package org.bepass.oblivion;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomsheet.BottomSheetDialogFragment;

import org.bepass.oblivion.utils.FileManager;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class EndpointsBottomSheet extends BottomSheetDialogFragment {
    private List<Endpoint> endpointsList;
    public EndpointSelectionListener selectionListener;
    private EndpointsAdapter adapter;

    @SuppressLint("NotifyDataSetChanged")
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.bottom_sheet_endpoints, container, false);

        RecyclerView recyclerView = view.findViewById(R.id.recyclerView);
        Button saveButton = view.findViewById(R.id.saveButton);
        EditText titleEditText = view.findViewById(R.id.titleEditText);
        EditText contentEditText = view.findViewById(R.id.contentEditText);

        endpointsList = new ArrayList<>();
        loadEndpoints();

        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new EndpointsAdapter(endpointsList, this::onEndpointSelected);
        recyclerView.setAdapter(adapter);

        // Handle save button press
        saveButton.setOnClickListener(v -> {
            String title = titleEditText.getText().toString().trim();
            String content = contentEditText.getText().toString().trim();

            if (!title.isEmpty() && !content.isEmpty()) {
                Endpoint newEndpoint = new Endpoint(title, content);
                saveEndpoint(newEndpoint);
                adapter.notifyDataSetChanged(); // Refresh the RecyclerView

                // Clear the input fields
                titleEditText.setText("");
                contentEditText.setText("");
            }
        });

        return view;
    }

    private void loadEndpoints() {
        Set<String> savedEndpoints = FileManager.getStringSet("saved_endpoints", new HashSet<>());
        for (String endpoint : savedEndpoints) {
            String[] parts = endpoint.split("::");
            if (parts.length == 2) {
                endpointsList.add(new Endpoint(parts[0], parts[1]));
            }
        }
    }

    private void saveEndpoint(Endpoint endpoint) {
        endpointsList.add(endpoint);

        // Save to FileManager
        Set<String> savedEndpoints = FileManager.getStringSet("saved_endpoints", new HashSet<>());
        savedEndpoints.add(endpoint.getTitle() + "::" + endpoint.getContent());
        FileManager.set("saved_endpoints", savedEndpoints);
    }

    private void onEndpointSelected(String content) {
        if (selectionListener != null) {
            selectionListener.onEndpointSelected(content);
        }
        dismiss(); // Close the bottom sheet after selection
    }

    public void setEndpointSelectionListener(EndpointSelectionListener listener) {
        this.selectionListener = listener;
    }

    private static class Endpoint {
        private final String title;
        private final String content;

        Endpoint(String title, String content) {
            this.title = title;
            this.content = content;
        }

        public String getTitle() {
            return title;
        }

        public String getContent() {
            return content;
        }
    }

    private static class EndpointsAdapter extends RecyclerView.Adapter<EndpointsAdapter.EndpointViewHolder> {
        private final List<Endpoint> endpointsList;
        public final EndpointSelectionListener selectionListener;

        EndpointsAdapter(List<Endpoint> endpointsList, EndpointSelectionListener selectionListener) {
            this.endpointsList = endpointsList;
            this.selectionListener = selectionListener;
        }

        @NonNull
        @Override
        public EndpointViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_endpoint, parent, false);
            return new EndpointViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull EndpointViewHolder holder, int position) {
            Endpoint endpoint = endpointsList.get(position);
            holder.titleTextView.setText(endpoint.getTitle());
            holder.contentTextView.setText(endpoint.getContent());

            holder.itemView.setOnClickListener(v -> {
                if (selectionListener != null) {
                    selectionListener.onEndpointSelected(endpoint.getContent());
                }
            });
        }

        @Override
        public int getItemCount() {
            return endpointsList.size();
        }

        static class EndpointViewHolder extends RecyclerView.ViewHolder {
            TextView titleTextView, contentTextView;

            EndpointViewHolder(@NonNull View itemView) {
                super(itemView);
                titleTextView = itemView.findViewById(R.id.titleTextView);
                contentTextView = itemView.findViewById(R.id.contentTextView);
            }
        }
    }

    public interface EndpointSelectionListener {
        void onEndpointSelected(String content);
    }
}