require 'dotenv/load'
require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require_relative 'database'
require_relative 'models'
require_relative 'repository'

configure do
  enable :cross_origin
  set :bind, '0.0.0.0'
  set :port, 4567
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  content_type :json
end

options '*' do
  response.headers['Allow'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  200
end

DB = Database.new(
  host:     ENV.fetch('DB_HOST',     'localhost'),
  port:     ENV.fetch('DB_PORT',     5432).to_i,
  dbname:   ENV.fetch('DB_NAME',     'mi_tienda'),   # misma db
  user:     ENV.fetch('DB_USER',     'damasko'),      # mismo usuario
  password: ENV.fetch('DB_PASSWORD', '')
)
REPO = ProductoRepository.new(DB)
REPO.crear_tabla

def respuesta(data: nil, mensaje: nil, status: 200)
  body = {}
  body[:mensaje] = mensaje if mensaje
  body[:data]    = data    unless data.nil?
  halt status, body.to_json
end

# ── GET /productos ───────────────────────────────────────────────────────────
get '/productos' do
  productos = REPO.obtener_todos
  respuesta(data: productos.map(&:to_h))
end

# ── GET /productos/buscar?nombre=x ───────────────────────────────────────────
get '/productos/buscar' do
  nombre = params['nombre'].to_s.strip
  return respuesta(mensaje: "Parámetro 'nombre' requerido.", status: 400) if nombre.empty?
  resultados = REPO.buscar_por_nombre(nombre)
  respuesta(data: resultados.map(&:to_h))
end

# ── GET /productos/:id ───────────────────────────────────────────────────────
get '/productos/:id' do
  producto = REPO.obtener_por_id(params[:id].to_i)
  return respuesta(mensaje: 'Producto no encontrado.', status: 404) unless producto
  respuesta(data: producto.to_h)
end

# ── POST /productos ──────────────────────────────────────────────────────────
post '/productos' do
  body = JSON.parse(request.body.read)
  producto = Producto.new(
    nombre: body['nombre'],
    precio: body['precio'].to_f,
    stock:  body.fetch('stock', 0).to_i
  )
  producto = REPO.crear(producto)
  respuesta(data: producto.to_h, mensaje: 'Producto creado.', status: 201)
rescue JSON::ParserError
  respuesta(mensaje: 'JSON inválido.', status: 400)
rescue ArgumentError, KeyError => e
  respuesta(mensaje: e.message, status: 400)
end

# ── PUT /productos/:id ───────────────────────────────────────────────────────
put '/productos/:id' do
  producto = REPO.obtener_por_id(params[:id].to_i)
  return respuesta(mensaje: 'Producto no encontrado.', status: 404) unless producto
  body = JSON.parse(request.body.read)
  producto.nombre = body.fetch('nombre', producto.nombre)
  producto.precio = body.fetch('precio', producto.precio).to_f
  producto.stock  = body.fetch('stock',  producto.stock).to_i
  REPO.actualizar(producto)
  respuesta(data: producto.to_h, mensaje: 'Producto actualizado.')
rescue JSON::ParserError
  respuesta(mensaje: 'JSON inválido.', status: 400)
rescue ArgumentError => e
  respuesta(mensaje: e.message, status: 400)
end

# ── PATCH /productos/:id/stock ───────────────────────────────────────────────
patch '/productos/:id/stock' do
  body = JSON.parse(request.body.read)
  nuevo_stock = body.fetch('stock').to_i
  ok = REPO.actualizar_stock(params[:id].to_i, nuevo_stock)
  return respuesta(mensaje: 'Producto no encontrado.', status: 404) unless ok
  respuesta(mensaje: "Stock actualizado a #{nuevo_stock}.")
rescue JSON::ParserError, KeyError
  respuesta(mensaje: "Campo 'stock' requerido.", status: 400)
end

# ── DELETE /productos/:id ────────────────────────────────────────────────────
delete '/productos/:id' do
  ok = REPO.eliminar(params[:id].to_i)
  return respuesta(mensaje: 'Producto no encontrado.', status: 404) unless ok
  respuesta(mensaje: 'Producto eliminado.')
end
