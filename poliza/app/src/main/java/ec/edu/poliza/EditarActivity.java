package ec.edu.poliza;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import ec.edu.poliza.controlador.PolizaController;
import ec.edu.poliza.modelo.Poliza;

public class EditarActivity extends AppCompatActivity {
    private Spinner spPolizas, spModelo, spEdad;
    private EditText etNombre, etValor, etAccidentes;
    private TextView tvResultado;
    private Button btnActualizar, btnLimpiar, btnSalir;
    private PolizaController polizaController;
    private List<Poliza> listaPolizas;
    private Poliza polizaSeleccionada;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_editar);

        // Inicializar controlador
        polizaController = new PolizaController(this);

        // Mapear vistas
        spPolizas = findViewById(R.id.sp_polizas);
        spModelo = findViewById(R.id.sp_modelo);
        spEdad = findViewById(R.id.sp_edad);
        etNombre = findViewById(R.id.et_nombre);
        etValor = findViewById(R.id.et_valor_alquiler);
        etAccidentes = findViewById(R.id.et_numero_acci);
        tvResultado = findViewById(R.id.tv_resultado);
        btnActualizar = findViewById(R.id.bt_actualizar);
        btnLimpiar = findViewById(R.id.bt_limpiar);
        btnSalir = findViewById(R.id.bt_salir);

        // Cargar spinners
        cargarSpinners();

        // Configurar listener para el spinner de pólizas
        spPolizas.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                polizaSeleccionada = listaPolizas.get(position);
                cargarDatosPoliza(polizaSeleccionada);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        // Configurar botones
        btnActualizar.setOnClickListener(v -> actualizarPoliza());
        btnLimpiar.setOnClickListener(v -> limpiarCampos());
        btnSalir.setOnClickListener(v -> finish());
    }

    private void cargarSpinners() {
        // Cargar spinner de pólizas
        listaPolizas = polizaController.obtenerTodasLasPolizas();
        List<String> nombresPolizas = new ArrayList<>();
        for (Poliza poliza : listaPolizas) {
            nombresPolizas.add(poliza.getNombre() + " - ID: " + poliza.getId());
        }
        ArrayAdapter<String> polizasAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, nombresPolizas);
        polizasAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spPolizas.setAdapter(polizasAdapter);

        // Cargar spinner de modelos
        List<String> modelos = Arrays.asList("A", "B", "C");
        ArrayAdapter<String> modeloAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, modelos);
        modeloAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spModelo.setAdapter(modeloAdapter);

        // Cargar spinner de edades
        List<String> edades = Arrays.asList("18-23", "24-53", "Mayor de 53");
        ArrayAdapter<String> edadAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, edades);
        edadAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spEdad.setAdapter(edadAdapter);
    }

    private void cargarDatosPoliza(Poliza poliza) {
        etNombre.setText(poliza.getNombre());
        etValor.setText(String.valueOf(poliza.getValor()));
        etAccidentes.setText(String.valueOf(poliza.getAccidentes()));

        // Seleccionar modelo en spinner
        int modeloPos = ((ArrayAdapter) spModelo.getAdapter())
                .getPosition(poliza.getModelo());
        spModelo.setSelection(modeloPos);

        // Seleccionar edad en spinner
        int edadPos = ((ArrayAdapter) spEdad.getAdapter())
                .getPosition(poliza.getEdad());
        spEdad.setSelection(edadPos);

        tvResultado.setText("Costo de la Póliza: " + poliza.getCostoPoliza());
    }

    private void actualizarPoliza() {
        if (polizaSeleccionada == null) {
            Toast.makeText(this, "Por favor seleccione una póliza", Toast.LENGTH_SHORT).show();
            return;
        }

        String nombre = etNombre.getText().toString();
        String valorStr = etValor.getText().toString();
        String accidentesStr = etAccidentes.getText().toString();

        if (nombre.isEmpty() || valorStr.isEmpty() || accidentesStr.isEmpty()) {
            Toast.makeText(this, "Por favor complete todos los campos", Toast.LENGTH_SHORT).show();
            return;
        }

        try {
            double valor = Double.parseDouble(valorStr);
            int accidentes = Integer.parseInt(accidentesStr);
            String modelo = spModelo.getSelectedItem().toString();
            String edad = spEdad.getSelectedItem().toString();

            boolean actualizado = polizaController.actualizarPoliza(
                    polizaSeleccionada.getId(),
                    nombre,
                    valor,
                    accidentes,
                    modelo,
                    edad
            );

            if (actualizado) {
                Toast.makeText(this, "Póliza actualizada correctamente", Toast.LENGTH_SHORT).show();
                // Recargar datos
                cargarSpinners();
            } else {
                Toast.makeText(this, "Error al actualizar la póliza", Toast.LENGTH_SHORT).show();
            }

        } catch (NumberFormatException e) {
            Toast.makeText(this, "Por favor ingrese valores numéricos válidos", Toast.LENGTH_SHORT).show();
        }
    }

    private void limpiarCampos() {
        etNombre.setText("");
        etValor.setText("");
        etAccidentes.setText("");
        spModelo.setSelection(0);
        spEdad.setSelection(0);
        tvResultado.setText("Costo de la Póliza: ");
    }
}