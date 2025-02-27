package ec.edu.poliza;

import androidx.appcompat.app.AppCompatActivity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

public class MainActivity extends AppCompatActivity {

    private Button btnAgregar;
    private Button btnEditar;
    private Button btnEliminar;
    private Button btnVisualizar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_menu);

        // Inicializar los botones
        btnAgregar = findViewById(R.id.btnAgregar);
        btnEditar = findViewById(R.id.btnEditar);
        btnEliminar = findViewById(R.id.btnEliminar);
        btnVisualizar = findViewById(R.id.btnVisualizar);

        // Configurar el click listener para el botón Agregar
        btnAgregar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, AgregarActivity.class);
                startActivity(intent);
            }
        });

        btnEditar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, EditarActivity.class);
                startActivity(intent);
            }
        });

        btnEliminar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, EliminarActivity.class);
                startActivity(intent);
            }
        });

        btnVisualizar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, VisualizarActivity.class);
                startActivity(intent);
            }
        });
    }
}