require_relative 'models'

class ProductoRepository
  def initialize(db)
    @db = db
  end

  def crear_tabla
    @db.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS productos (
        id          SERIAL PRIMARY KEY,
        nombre      VARCHAR(150) NOT NULL,
        precio      NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
        stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
        creado_en   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
    puts "✅ Tabla 'productos' verificada/creada."
  end

  # ── CREATE ────────────────────────────────────────────────────────────────

  def crear(producto)
    result = @db.execute(
      "INSERT INTO productos (nombre, precio, stock) VALUES ($1, $2, $3) RETURNING id, creado_en;",
      [producto.nombre, producto.precio, producto.stock]
    )
    producto.id        = result[0]['id']
    producto.creado_en = result[0]['creado_en']
    producto
  end

  # ── READ ──────────────────────────────────────────────────────────────────

  def obtener_por_id(id)
    result = @db.execute("SELECT * FROM productos WHERE id = $1;", [id])
    return nil if result.ntuples.zero?
    Producto.from_h(result[0])
  end

  def obtener_todos
    result = @db.execute("SELECT * FROM productos ORDER BY id;")
    result.map { |row| Producto.from_h(row) }
  end

  def buscar_por_nombre(nombre)
    result = @db.execute(
      "SELECT * FROM productos WHERE nombre ILIKE $1 ORDER BY id;",
      ["%#{nombre}%"]
    )
    result.map { |row| Producto.from_h(row) }
  end

  # ── UPDATE ────────────────────────────────────────────────────────────────

  def actualizar(producto)
    raise ArgumentError, "El producto debe tener un id." if producto.id.nil?
    result = @db.execute(
      "UPDATE productos SET nombre=$1, precio=$2, stock=$3 WHERE id=$4;",
      [producto.nombre, producto.precio, producto.stock, producto.id]
    )
    result.cmd_tuples > 0
  end

  def actualizar_stock(id, nuevo_stock)
    result = @db.execute(
      "UPDATE productos SET stock=$1 WHERE id=$2;",
      [nuevo_stock, id]
    )
    result.cmd_tuples > 0
  end

  # ── DELETE ────────────────────────────────────────────────────────────────

  def eliminar(id)
    result = @db.execute("DELETE FROM productos WHERE id=$1;", [id])
    result.cmd_tuples > 0
  end
end
