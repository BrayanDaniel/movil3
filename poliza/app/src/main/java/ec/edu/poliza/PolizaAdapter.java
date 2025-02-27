package ec.edu.poliza;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import java.util.List;

import ec.edu.poliza.R;
import ec.edu.poliza.controlador.PolizaController;
import ec.edu.poliza.modelo.Poliza;

public class PolizaAdapter extends ArrayAdapter<Poliza> {
    private Context context;
    private List<Poliza> polizas;

    public PolizaAdapter(Context context, List<Poliza> polizas) {
        super(context, 0, polizas);
        this.context = context;
        this.polizas = polizas;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        View listItem = convertView;
        if (listItem == null) {
            listItem = LayoutInflater.from(context).inflate(R.layout.item_poliza, parent, false);
        }

        Poliza polizaActual = polizas.get(position);

        TextView nombre = listItem.findViewById(R.id.tv_nombre);
        TextView detalles = listItem.findViewById(R.id.tv_detalles);
        TextView costo = listItem.findViewById(R.id.tv_costo);

        nombre.setText(polizaActual.getNombre());
        detalles.setText(String.format("Modelo: %s | Edad: %s | Accidentes: %d",
                polizaActual.getModelo(),
                polizaActual.getEdad(),
                polizaActual.getAccidentes()));
        costo.setText(String.format("Costo: $%.2f", polizaActual.getCostoPoliza()));

        return listItem;
    }

    public void filtrar(String texto) {
        List<Poliza> todasLasPolizas = new PolizaController(context).obtenerTodasLasPolizas();
        polizas.clear();
        if (texto.isEmpty()) {
            polizas.addAll(todasLasPolizas);
        } else {
            texto = texto.toLowerCase();
            for (Poliza poliza : todasLasPolizas) {
                if (poliza.getNombre().toLowerCase().contains(texto)) {
                    polizas.add(poliza);
                }
            }
        }
        notifyDataSetChanged();
    }
}