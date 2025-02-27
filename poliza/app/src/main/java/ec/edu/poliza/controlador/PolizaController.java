package ec.edu.poliza.controlador;

import android.annotation.SuppressLint;
import android.content.Context;
import android.database.Cursor;

import java.util.ArrayList;
import java.util.List;

import ec.edu.poliza.database.DatabaseHelper;
import ec.edu.poliza.modelo.Poliza;

public class PolizaController {
    private DatabaseHelper dbHelper;

    public PolizaController(Context context) {
        dbHelper = new DatabaseHelper(context);
    }

    // Método para crear una nueva póliza
    public boolean crearPoliza(String nombre, double valor, int accidentes, String modelo, String edad) {
        double costoTotal = Double.parseDouble(calcularCosto(nombre, (int)valor, accidentes, modelo, edad));
        return dbHelper.insertPoliza(nombre, valor, accidentes, modelo, edad, costoTotal);
    }

    // Método para obtener todas las pólizas
    public List<Poliza> obtenerTodasLasPolizas() {
        List<Poliza> listaPolizas = new ArrayList<>();
        Cursor cursor = dbHelper.getAllPolizas();

        if (cursor.moveToFirst()) {
            do {
                @SuppressLint("Range") Poliza poliza = new Poliza(
                        cursor.getLong(cursor.getColumnIndex(DatabaseHelper.COLUMN_ID)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_NOMBRE)),
                        cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_VALOR)),
                        cursor.getInt(cursor.getColumnIndex(DatabaseHelper.COLUMN_ACCIDENTES)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_MODELO)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_EDAD)),
                        cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_COSTO))
                );
                listaPolizas.add(poliza);
            } while (cursor.moveToNext());
        }
        cursor.close();
        return listaPolizas;
    }

    // Método para obtener una póliza por ID
    public Poliza obtenerPolizaPorId(long id) {
        Cursor cursor = dbHelper.getPolizaById(id);
        if (cursor.moveToFirst()) {
            @SuppressLint("Range") Poliza poliza = new Poliza(
                    cursor.getLong(cursor.getColumnIndex(DatabaseHelper.COLUMN_ID)),
                    cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_NOMBRE)),
                    cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_VALOR)),
                    cursor.getInt(cursor.getColumnIndex(DatabaseHelper.COLUMN_ACCIDENTES)),
                    cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_MODELO)),
                    cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_EDAD)),
                    cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_COSTO))
            );
            cursor.close();
            return poliza;
        }
        cursor.close();
        return null;
    }

    // Método para actualizar una póliza
    public boolean actualizarPoliza(long id, String nombre, double valor, int accidentes, String modelo, String edad) {
        double costoTotal = Double.parseDouble(calcularCosto(nombre, (int)valor, accidentes, modelo, edad));
        int result = dbHelper.updatePoliza(id, nombre, valor, accidentes, modelo, edad, costoTotal);
        return result > 0;
    }

    // Método para eliminar una póliza
    public boolean eliminarPoliza(long id) {
        return dbHelper.deletePoliza(id);
    }

    // Método para buscar pólizas por nombre
    public List<Poliza> buscarPolizasPorNombre(String nombre) {
        List<Poliza> listaPolizas = new ArrayList<>();
        Cursor cursor = dbHelper.buscarPolizasPorNombre(nombre);

        if (cursor.moveToFirst()) {
            do {
                @SuppressLint("Range") Poliza poliza = new Poliza(
                        cursor.getLong(cursor.getColumnIndex(DatabaseHelper.COLUMN_ID)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_NOMBRE)),
                        cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_VALOR)),
                        cursor.getInt(cursor.getColumnIndex(DatabaseHelper.COLUMN_ACCIDENTES)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_MODELO)),
                        cursor.getString(cursor.getColumnIndex(DatabaseHelper.COLUMN_EDAD)),
                        cursor.getDouble(cursor.getColumnIndex(DatabaseHelper.COLUMN_COSTO))
                );
                listaPolizas.add(poliza);
            } while (cursor.moveToNext());
        }
        cursor.close();
        return listaPolizas;
    }

    // Tu método existente de calcular costo con una corrección en el modelo "B"
    public static String calcularCosto(String nombre, int valor, int accidentes, String modelo, String edad) {
        // Cargo por valor (corregido)
        double cargoXValor = valor * 0.035;

        // Cargo por accidentes previos (correcto)
        double cargoXAccidentesPrevios = 0;
        if (accidentes > 0) {
            if (accidentes <= 3) {
                cargoXAccidentesPrevios = accidentes * 17;
            } else {
                cargoXAccidentesPrevios = (3 * 17) + ((accidentes - 3) * 21);
            }
        }

        // Cargo por modelo (correcto)
        double cargoXModelo = 0;
        if (modelo.equals("A")) {
            cargoXModelo = valor * 0.011;
        } else if (modelo.equals("B")) {
            cargoXModelo = valor * 0.012;
        } else if (modelo.equals("C")) {
            cargoXModelo = valor * 0.015;
        }

        // Cargo por edad (verificación mejorada)
        double cargoXEdad = 0;
        if (edad.equals("18-23")) {
            cargoXEdad = 360;
        } else if (edad.equals("24-53")) {
            cargoXEdad = 240;
        } else if (edad.equals("Mayor de 53")) {
            cargoXEdad = 430;
        } else {
            throw new IllegalArgumentException("Edad fuera de rango permitido.");
        }

        double costoTotal = cargoXValor + cargoXAccidentesPrevios + cargoXModelo + cargoXEdad;
        return String.valueOf(costoTotal);
    }

}