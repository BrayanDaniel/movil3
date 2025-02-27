package ec.edu.poliza;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.widget.ListView;

import ec.edu.poliza.controlador.PolizaController;

public class VisualizarActivity extends AppCompatActivity {
    private EditText etBuscar;
    private ListView lvPolizas;
    private PolizaAdapter adapter;
    private PolizaController polizaController;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_visualizar);

        // Inicializar componentes
        etBuscar = findViewById(R.id.et_buscar);
        lvPolizas = findViewById(R.id.lv_polizas);
        polizaController = new PolizaController(this);

        // Configurar adaptador
        adapter = new PolizaAdapter(this, polizaController.obtenerTodasLasPolizas());
        lvPolizas.setAdapter(adapter);

        // Configurar búsqueda en tiempo real
        etBuscar.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                adapter.filtrar(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });
    }
}