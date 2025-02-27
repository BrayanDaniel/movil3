package ec.edu.poliza.modelo;

public class Poliza {
    private long id;
    private String nombre;
    private double valor;
    private int accidentes;
    private String modelo;
    private String edad;
    private double costoPoliza;

    public Poliza(long id, String nombre, double valor, int accidentes, String modelo, String edad, double costoPoliza) {
        this.id = id;
        this.nombre = nombre;
        this.valor = valor;
        this.accidentes = accidentes;
        this.modelo = modelo;
        this.edad = edad;
        this.costoPoliza = costoPoliza;
    }


    // Getters y Setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public double getValor() { return valor; }
    public void setValor(double valor) { this.valor = valor; }
    public int getAccidentes() { return accidentes; }
    public void setAccidentes(int accidentes) { this.accidentes = accidentes; }
    public String getModelo() { return modelo; }
    public void setModelo(String modelo) { this.modelo = modelo; }
    public String getEdad() { return edad; }
    public void setEdad(String edad) { this.edad = edad; }
    public double getCostoPoliza() { return costoPoliza; }
    public void setCostoPoliza(double costoPoliza) { this.costoPoliza = costoPoliza; }


}