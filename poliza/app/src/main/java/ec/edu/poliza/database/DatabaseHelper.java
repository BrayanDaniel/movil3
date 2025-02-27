package ec.edu.poliza.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import androidx.annotation.Nullable;

public class DatabaseHelper extends SQLiteOpenHelper {
    private static final String DATABASE_NAME = "poliza.db";
    private static final int DATABASE_VERSION = 1;
    private static final String TABLE_NAME = "polizas";

    // Hacer públicas las constantes de columna para acceso desde otras clases
    public static final String COLUMN_ID = "id";
    public static final String COLUMN_NOMBRE = "nombre";
    public static final String COLUMN_VALOR = "valor_auto";
    public static final String COLUMN_ACCIDENTES = "accidentes";
    public static final String COLUMN_MODELO = "modelo";
    public static final String COLUMN_EDAD = "edad";
    public static final String COLUMN_COSTO = "costo_poliza";

    private static final String TABLE_CREATE =
            "CREATE TABLE " + TABLE_NAME + " (" +
                    COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    COLUMN_NOMBRE + " TEXT NOT NULL, " +
                    COLUMN_VALOR + " REAL NOT NULL, " +
                    COLUMN_ACCIDENTES + " INTEGER NOT NULL, " +
                    COLUMN_MODELO + " TEXT NOT NULL, " +
                    COLUMN_EDAD + " TEXT NOT NULL, " +
                    COLUMN_COSTO + " REAL NOT NULL);";

    public DatabaseHelper(@Nullable Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase sqLiteDatabase) {
        sqLiteDatabase.execSQL(TABLE_CREATE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase sqLiteDatabase, int oldVersion, int newVersion) {
        sqLiteDatabase.execSQL("DROP TABLE IF EXISTS " + TABLE_NAME);
        onCreate(sqLiteDatabase);
    }

    // Método para insertar una nueva póliza
    public boolean insertPoliza(String nombre, double valor, int accidentes, String modelo, String edad, double costo) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put(COLUMN_NOMBRE, nombre);
        values.put(COLUMN_VALOR, valor);
        values.put(COLUMN_ACCIDENTES, accidentes);
        values.put(COLUMN_MODELO, modelo);
        values.put(COLUMN_EDAD, edad);
        values.put(COLUMN_COSTO, costo);

        long result = db.insert(TABLE_NAME, null, values);
        return result != -1;
    }

    // Método para actualizar una póliza existente
    public int updatePoliza(long id, String nombre, double valor, int accidentes, String modelo, String edad, double costo) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put(COLUMN_NOMBRE, nombre);
        values.put(COLUMN_VALOR, valor);
        values.put(COLUMN_ACCIDENTES, accidentes);
        values.put(COLUMN_MODELO, modelo);
        values.put(COLUMN_EDAD, edad);
        values.put(COLUMN_COSTO, costo);

        return db.update(TABLE_NAME, values, COLUMN_ID + " = ?", new String[]{String.valueOf(id)});
    }

    // Método para eliminar una póliza
    public boolean deletePoliza(long id) {
        SQLiteDatabase db = this.getWritableDatabase();
        int result = db.delete(TABLE_NAME, COLUMN_ID + " = ?", new String[]{String.valueOf(id)});
        return result > 0;
    }

    // Método para obtener todas las pólizas
    public Cursor getAllPolizas() {
        SQLiteDatabase db = this.getReadableDatabase();
        return db.query(TABLE_NAME, null, null, null, null, null, COLUMN_ID + " ASC");
    }

    // Método para obtener una póliza específica por ID
    public Cursor getPolizaById(long id) {
        SQLiteDatabase db = this.getReadableDatabase();
        return db.query(TABLE_NAME, null, COLUMN_ID + " = ?", new String[]{String.valueOf(id)}, null, null, null);
    }

    // Método para verificar si una póliza existe
    public boolean existePoliza(long id) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query(TABLE_NAME, new String[]{COLUMN_ID}, COLUMN_ID + " = ?",
                new String[]{String.valueOf(id)}, null, null, null);
        boolean existe = cursor.getCount() > 0;
        cursor.close();
        return existe;
    }

    // Método para obtener el número total de pólizas
    public int getCountPolizas() {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.rawQuery("SELECT COUNT(*) FROM " + TABLE_NAME, null);
        cursor.moveToFirst();
        int count = cursor.getInt(0);
        cursor.close();
        return count;
    }

    // Método para eliminar todas las pólizas
    public void deleteAllPolizas() {
        SQLiteDatabase db = this.getWritableDatabase();
        db.delete(TABLE_NAME, null, null);
    }

    // Método para buscar pólizas por nombre
    public Cursor buscarPolizasPorNombre(String nombre) {
        SQLiteDatabase db = this.getReadableDatabase();
        return db.query(TABLE_NAME, null, COLUMN_NOMBRE + " LIKE ?",
                new String[]{"%" + nombre + "%"}, null, null, COLUMN_ID + " ASC");
    }
}