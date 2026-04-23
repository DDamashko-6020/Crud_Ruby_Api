class Producto
  attr_accessor :id, :nombre, :precio, :stock, :creado_en

  def initialize(nombre:, precio:, stock:, id: nil, creado_en: nil)
    @id        = id
    @nombre    = nombre
    @precio    = precio.to_f
    @stock     = stock.to_i
    @creado_en = creado_en
    validar!
  end

  def validar!
    raise ArgumentError, "El nombre no puede estar vacío."      if @nombre.strip.empty?
    raise ArgumentError, "El precio no puede ser negativo."     if @precio < 0
    raise ArgumentError, "El stock no puede ser negativo."      if @stock < 0
  end

  def to_h
    {
      id:        @id,
      nombre:    @nombre,
      precio:    @precio,
      stock:     @stock,
      creado_en: @creado_en&.to_s
    }
  end

  def self.from_h(data)
    new(
      id:        data['id'] || data[:id],
      nombre:    data['nombre'] || data[:nombre],
      precio:    data['precio'] || data[:precio],
      stock:     data['stock']  || data[:stock],
      creado_en: data['creado_en'] || data[:creado_en]
    )
  end

  def to_s
    "Producto(id=#{@id}, nombre='#{@nombre}', precio=#{'%.2f' % @precio}, stock=#{@stock})"
  end
end
