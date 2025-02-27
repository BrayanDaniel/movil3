package ec.edu.poliza;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AlertDialog;

import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

import ec.edu.poliza.controlador.PolizaController;
import ec.edu.poliza.modelo.Poliza;

public class EliminarActivity extends AppCompatActivity {
    private Spinner spPolizas;
    private TextView tvNombre, tvValor, tvAccidentes, tvModelo, tvEdad, tvCosto;
    private Button btnEliminar, btnSalir;
    private PolizaController polizaController;
    private List<Poliza> listaPolizas;
    private Poliza polizaSeleccionada;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_eliminar);

        // Inicializar controlador
        polizaController = new PolizaController(this);

        // Mapear vistas
        spPolizas = findViewById(R.id.sp_polizas);
        tvNombre = findViewById(R.id.tv_nombre);
        tvValor = findViewById(R.id.tv_valor);
        tvAccidentes = findViewById(R.id.tv_accidentes);
        tvModelo = findViewById(R.id.tv_modelo);
        tvEdad = findViewById(R.id.tv_edad);
        tvCosto = findViewById(R.id.tv_costo);
        btnEliminar = findViewById(R.id.bt_eliminar);
        btnSalir = findViewById(R.id.bt_salir);

        // Cargar spinner de pólizas
        cargarPolizas();

        // Configurar listener para el spinner
        spPolizas.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                polizaSeleccionada = listaPolizas.get(position);
                mostrarDatosPoliza(polizaSeleccionada);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        // Configurar botones
        btnEliminar.setOnClickListener(v -> confirmarEliminar());
        btnSalir.setOnClickListener(v -> finish());
    }

    private void cargarPolizas() {
        listaPolizas = polizaController.obtenerTodasLasPolizas();
        List<String> nombresPolizas = new ArrayList<>();
        for (Poliza poliza : listaPolizas) {
            nombresPolizas.add(poliza.getNombre() + " - ID: " + poliza.getId());
        }
        ArrayAdapter<String> polizasAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, nombresPolizas);
        polizasAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spPolizas.setAdapter(polizasAdapter);
    }

    private void mostrarDatosPoliza(Poliza poliza) {
        tvNombre.setText(poliza.getNombre());
        tvValor.setText(String.format("$%.2f", poliza.getValor()));
        tvAccidentes.setText(String.valueOf(poliza.getAccidentes()));
        tvModelo.setText(poliza.getModelo());
        tvEdad.setText(poliza.getEdad());
        tvCosto.setText(String.format("$%.2f", poliza.getCostoPoliza()));
    }

    private void confirmarEliminar() {
        if (polizaSeleccionada == null) {
            Toast.makeText(this, "Por favor seleccione una póliza", Toast.LENGTH_SHORT).show();
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Confirmar eliminación")
                .setMessage("¿Está seguro que desea eliminar esta póliza?")
                .setPositiveButton("Sí", (dialog, which) -> eliminarPoliza())
                .setNegativeButton("No", null)
                .show();
    }

    private void eliminarPoliza() {
        boolean eliminado = polizaController.eliminarPoliza(polizaSeleccionada.getId());

        if (eliminado) {
            Toast.makeText(this, "Póliza eliminada correctamente", Toast.LENGTH_SHORT).show();
            cargarPolizas(); // Recargar la lista
            if (listaPolizas.isEmpty()) {
                // Si no quedan pólizas, cerrar la actividad
                finish();
            }
        } else {
            Toast.makeText(this, "Error al eliminar la póliza", Toast.LENGTH_SHORT).show();
        }
    }
}