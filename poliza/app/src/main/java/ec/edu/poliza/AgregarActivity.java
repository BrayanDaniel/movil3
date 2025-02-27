package ec.edu.poliza;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Arrays;
import java.util.List;

import ec.edu.poliza.database.DatabaseHelper;

public class AgregarActivity extends AppCompatActivity {

    EditText txtNombre, txtValor, txtAccidentes;
    TextView lblResultado;
    Button btnCalcular, btnLimpiar, btnSalir;
    Spinner cboModelo, cboEdad;
    DatabaseHelper dbHelper;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_agregar);

        // Mapear objetos
        txtNombre = findViewById(R.id.et_nombre);
        txtValor = findViewById(R.id.et_valor_alquiler);
        txtAccidentes = findViewById(R.id.et_numero_acci);
        lblResultado = findViewById(R.id.tv_resultado);

        btnCalcular = findViewById(R.id.bt_calcular);
        btnLimpiar = findViewById(R.id.bt_limpiar);
        btnSalir = findViewById(R.id.bt_salir);

        cboModelo = findViewById(R.id.sp_modelo);
        cboEdad = findViewById(R.id.sp_edad);

        // Inicializar DatabaseHelper
        dbHelper = new DatabaseHelper(this);

        // Método para cargar datos en el spinner
        cargarDatosSpinner();

        // Eventos de los botones
        btnCalcular.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                calcularPoliza();
            }
        });

        btnLimpiar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                limpiar();
            }
        });

        btnSalir.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
    }

    // Método para cargar datos en el spinner
    private void cargarDatosSpinner() {
        // Cargar datos del modelo
        List<String> modelos = Arrays.asList("Modelo A", "Modelo B", "Modelo C");
        ArrayAdapter<String> modeloAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, modelos);
        modeloAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        cboModelo.setAdapter(modeloAdapter);

        // Cargar datos de la edad
        List<String> edades = Arrays.asList("18-23", "24-55", "Mayor de 55");
        ArrayAdapter<String> edadesAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, edades);
        edadesAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        cboEdad.setAdapter(edadesAdapter);
    }

    // Método para calcular póliza
    private void calcularPoliza() {
        String nombre = txtNombre.getText().toString();
        String valorStr = txtValor.getText().toString();
        String accidentesStr = txtAccidentes.getText().toString();
        String modelo = cboModelo.getSelectedItem().toString();
        String edad = cboEdad.getSelectedItem().toString();

        // Validación de los campos
        if (nombre.isEmpty() || valorStr.isEmpty() || accidentesStr.isEmpty()) {
            Toast.makeText(this, "Por favor complete todos los campos", Toast.LENGTH_SHORT).show();
            return;
        }

        double valor;
        int accidentes;
        try {
            valor = Double.parseDouble(valorStr);
        } catch (NumberFormatException e) {
            Toast.makeText(this, "Valor no válido", Toast.LENGTH_SHORT).show();
            return;
        }

        try {
            accidentes = Integer.parseInt(accidentesStr);
        } catch (NumberFormatException e) {
            Toast.makeText(this, "Número de accidentes no válido", Toast.LENGTH_SHORT).show();
            return;
        }

        // Calcular el costo de la póliza
        double costo = valor * 0.05;
        if (accidentes > 0) {
            costo += 100;
        }

        // Insertar datos en la base de datos
        boolean isInserted = dbHelper.insertPoliza(nombre, valor, accidentes, modelo, edad, costo);

        // Mostrar el resultado
        lblResultado.setText("Costo de la Póliza: " + costo);

        // Mostrar mensaje de éxito
        if (isInserted) {
            Toast.makeText(this, "Póliza guardada correctamente", Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(this, "Error al guardar la póliza", Toast.LENGTH_SHORT).show();
        }
    }

    private void limpiar() {
        txtNombre.setText("");
        txtValor.setText("");
        txtAccidentes.setText("");
        cboModelo.setSelection(0);
        cboEdad.setSelection(0);
        lblResultado.setText("");
    }
}