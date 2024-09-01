package org.bepass.oblivion;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
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
    private static List<Endpoint> endpointsList;
    public EndpointSelectionListener selectionListener;
    private EndpointsAdapter adapter;

    @SuppressLint("NotifyDataSetChanged")
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.bottom_sheet_endpoints, container, false);

        RecyclerView recyclerView = view.findViewById(R.id.recyclerView);
        Button saveButton = view.findViewById(R.id.saveButton);
        Button resetDefaultButton = view.findViewById(R.id.resetDefaultButton); // Add this line
        EditText titleEditText = view.findViewById(R.id.titleEditText);
        EditText contentEditText = view.findViewById(R.id.contentEditText);

        endpointsList = new ArrayList<>();
        loadEndpoints();

        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new EndpointsAdapter(endpointsList, this::onEndpointSelected);
        recyclerView.setAdapter(adapter);

        saveButton.setOnClickListener(v -> {
            String title = titleEditText.getText().toString().trim();
            String content = contentEditText.getText().toString().trim();

            if (!title.isEmpty() && !content.isEmpty()) {
                Endpoint newEndpoint = new Endpoint(title, content);
                saveEndpoint(newEndpoint);
                adapter.notifyDataSetChanged();

                titleEditText.setText("");
                contentEditText.setText("");
            }
        });

        // Handle reset to default button press
        resetDefaultButton.setOnClickListener(v -> {
            endpointsList.clear();
            endpointsList.add(new Endpoint("Default", "engage.cloudflareclient.com:2408")); // Add default endpoint
            saveEndpoints(); // Save the updated list
            adapter.notifyDataSetChanged();
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

    private static void saveEndpoints() {
        Set<String> savedEndpoints = new HashSet<>();
        for (Endpoint endpoint : endpointsList) {
            savedEndpoints.add(endpoint.getTitle() + "::" + endpoint.getContent());
        }
        FileManager.set("saved_endpoints", savedEndpoints);
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

            // Handle delete button click
            holder.deleteIcon.setOnClickListener(v -> {
                // Remove the endpoint from the list and update the RecyclerView
                endpointsList.remove(position);
                notifyItemRemoved(position);
                notifyItemRangeChanged(position, endpointsList.size());

                // Save the updated list to FileManager
                saveEndpoints();
            });
        }

        @Override
        public int getItemCount() {
            return endpointsList.size();
        }

        static class EndpointViewHolder extends RecyclerView.ViewHolder {
            TextView titleTextView, contentTextView;
            ImageView deleteIcon; // Added for delete icon

            EndpointViewHolder(@NonNull View itemView) {
                super(itemView);
                titleTextView = itemView.findViewById(R.id.titleTextView);
                contentTextView = itemView.findViewById(R.id.contentTextView);
                deleteIcon = itemView.findViewById(R.id.delIcon); // Initialize delete icon
            }
        }
    }

    public interface EndpointSelectionListener {
        void onEndpointSelected(String content);
    }
}