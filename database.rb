require 'pg'

class Database
  def initialize(host:, port:, dbname:, user:, password:)
    @host     = host
    @port     = port
    @dbname   = dbname
    @user     = user
    @password = password
    @connection = nil
  end

  def connect
    if @connection.nil? || @connection.finished?
      @connection = PG.connect(
        host:     @host,
        port:     @port,
        dbname:   @dbname,
        user:     @user,
        password: @password
      )
      @connection.type_map_for_results = PG::BasicTypeMapForResults.new(@connection)
    end
    @connection
  end

  def disconnect
    @connection&.finish unless @connection&.finished?
  end

  def execute(sql, params = [])
    conn = connect
    conn.exec_params(sql, params)
  end

  def transaction
    conn = connect
    conn.transaction { yield conn }
  end

  def with_connection
    connect
    yield self
  ensure
    disconnect
  end
end
