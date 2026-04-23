require_relative 'database'
require_relative 'models'
require_relative 'repository'

DB = Database.new(
  host:     ENV.fetch('DB_HOST',     'localhost'),
  port:     ENV.fetch('DB_PORT',     5432).to_i,
  dbname:   ENV.fetch('DB_NAME',     'mi_tienda'),
  user:     ENV.fetch('DB_USER',     'damasko'),
  password: ENV.fetch('DB_PASSWORD', '')
)

REPO = ProductoRepository.new(DB)
REPO.crear_tabla

def separador = puts '─' * 45
def pausar    = (print "\n  Presiona Enter para continuar..."; gets)
def limpiar   = puts "\n\n"

def mostrar_menu
  separador
  puts '       🛒  GESTOR DE PRODUCTOS (Ruby)'
  separador
  puts '  1. Listar todos los productos'
  puts '  2. Buscar producto por ID'
  puts '  3. Buscar producto por nombre'
  puts '  4. Agregar nuevo producto'
  puts '  5. Actualizar producto'
  puts '  6. Actualizar stock'
  puts '  7. Eliminar producto'
  puts '  0. Salir'
  separador
end

def listar_todos
  productos = REPO.obtener_todos
  if productos.empty?
    puts "\n  ⚠️  No hay productos registrados."
  else
    printf "\n  %-5s %-25s %12s %6s\n", 'ID', 'Nombre', 'Precio', 'Stock'
    separador
    productos.each do |p|
      printf "  %-5s %-25s %12s %6s\n", p.id, p.nombre, "$#{'%.0f' % p.precio}", p.stock
    end
  end
end

def buscar_por_id
  print "\n  ID del producto: "
  id = gets.to_i
  p = REPO.obtener_por_id(id)
  if p
    puts "\n  ✅ Encontrado:"
    puts "     ID      : #{p.id}"
    puts "     Nombre  : #{p.nombre}"
    puts "     Precio  : $#{'%.0f' % p.precio}"
    puts "     Stock   : #{p.stock}"
    puts "     Creado  : #{p.creado_en}"
  else
    puts "\n  ❌ No existe producto con ID #{id}."
  end
end

def buscar_por_nombre
  print "\n  Nombre a buscar: "
  nombre = gets.chomp.strip
  resultados = REPO.buscar_por_nombre(nombre)
  if resultados.empty?
    puts "\n  ❌ Sin resultados para '#{nombre}'."
  else
    puts "\n  #{resultados.size} resultado(s):"
    resultados.each { |p| puts "  [#{p.id}] #{p.nombre} — $#{'%.0f' % p.precio} — Stock: #{p.stock}" }
  end
end

def agregar_producto
  puts "\n  ── Nuevo Producto ──"
  print "  Nombre  : "; nombre = gets.chomp.strip
  print "  Precio  : "; precio = gets.to_f
  print "  Stock   : "; stock  = gets.to_i
  producto = Producto.new(nombre: nombre, precio: precio, stock: stock)
  producto = REPO.crear(producto)
  puts "\n  ✅ Producto creado con ID #{producto.id}."
rescue ArgumentError => e
  puts "\n  ⚠️  Error: #{e.message}"
end

def actualizar_producto
  print "\n  ID del producto a actualizar: "
  id = gets.to_i
  p = REPO.obtener_por_id(id)
  return puts "\n  ❌ No existe producto con ID #{id}." unless p

  puts "\n  Datos actuales: #{p}"
  puts "  (Deja en blanco para conservar el valor actual)"
  print "  Nuevo nombre [#{p.nombre}]: "; nombre = gets.chomp.strip
  print "  Nuevo precio [#{p.precio}]: "; precio = gets.chomp.strip
  print "  Nuevo stock  [#{p.stock}]: ";  stock  = gets.chomp.strip

  p.nombre = nombre.empty? ? p.nombre : nombre
  p.precio = precio.empty? ? p.precio : precio.to_f
  p.stock  = stock.empty?  ? p.stock  : stock.to_i
  ok = REPO.actualizar(p)
  puts ok ? "\n  ✅ Producto actualizado." : "\n  ❌ No se pudo actualizar."
rescue ArgumentError => e
  puts "\n  ⚠️  Error: #{e.message}"
end

def actualizar_stock
  print "\n  ID del producto: "; id    = gets.to_i
  print "  Nuevo stock    : "; stock = gets.to_i
  ok = REPO.actualizar_stock(id, stock)
  puts ok ? "\n  ✅ Stock actualizado." : "\n  ❌ Producto no encontrado."
end

def eliminar_producto
  print "\n  ID del producto a eliminar: "
  id = gets.to_i
  p = REPO.obtener_por_id(id)
  return puts "\n  ❌ No existe producto con ID #{id}." unless p

  print "  ¿Eliminar '#{p.nombre}'? (s/n): "
  if gets.chomp.strip.downcase == 's'
    REPO.eliminar(id)
    puts "\n  ✅ Producto eliminado."
  else
    puts "\n  ↩️  Operación cancelada."
  end
end

acciones = {
  '1' => method(:listar_todos),
  '2' => method(:buscar_por_id),
  '3' => method(:buscar_por_nombre),
  '4' => method(:agregar_producto),
  '5' => method(:actualizar_producto),
  '6' => method(:actualizar_stock),
  '7' => method(:eliminar_producto)
}

loop do
  limpiar
  mostrar_menu
  print "  Elige una opción: "
  opcion = gets.chomp.strip

  break puts("\n  👋 ¡Hasta luego!\n") if opcion == '0'

  if acciones.key?(opcion)
    acciones[opcion].call
    pausar
  else
    puts "\n  ⚠️  Opción no válida."
    pausar
  end
end

DB.disconnect
