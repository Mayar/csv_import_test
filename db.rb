require 'pg'

class DB
  RECONNECTION_ATTEMPTS = (ENV['RECONNECTION_ATTEMPTS'] || 5).to_i # minutes
  RECONNECTION_DELAY = (ENV['RECONNECTION_DELAY'] || 10).to_i # minutes

  attr_accessor :price

  def import(rows)
    @prep ||= @db.prepare('import', %Q{
      INSERT INTO public.products (price_list, brand, code, stock, cost, name, del)
      VALUES ($1, $2, $3, $4, $5, $6, false)
      ON CONFLICT ON CONSTRAINT products_pk
      DO UPDATE SET
        stock = $4,
        cost = $5,
        name = $6,
        del = false
    })
    @db.transaction do |conn|
      rows.each do |row|
        conn.exec_prepared('import', row)
      end
    end
  end

  def initialize(db_conn)
    @db_conn = db_conn
    @db ||= self.connect(db_conn)
  end

  def connect(db_conn = nil)
    PG.connect(db_conn || @db_conn)
  end

  def exec(query, params = [])
    raise "ERROR! Price not set!"  if @price.nil?
    reconnect_num = RECONNECTION_ATTEMPTS
    begin
      @db.exec(query, params)
    rescue PG::ConnectionBad, PG::UnableToSend, PG::AdminShutdown => exception
      puts 'No connection to database!'
      if reconnect_num > 0
        puts "Remaining #{reconnect_num} attempts. Reconnecting..."
        reconnect_num -= 1
        sleep RECONNECTION_DELAY
        self.connect
        retry
      else
        puts 'Can\'t establish connection to database.'
        raise exception
      end
    end
  end

  def mark_all_for_del
    exec("UPDATE products SET del=true WHERE price_list='#@price'")
  end

  def del_all_marked
    exec("DELETE FROM products WHERE price_list='#@price' AND del=true")
  end

  def close
    @db.close
  end
end
