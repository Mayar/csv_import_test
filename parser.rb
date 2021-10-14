class Parser
  WORDS_BRAND = %w[производитель бренд]
  WORDS_CODE = %w[артикул номер]
  WORDS_NAME = %w[наименование наименованиетовара]
  WORDS_STOCK = %w[количество кол-во]
  WORDS_COST = %w[цена]

  attr_reader :encoding
  attr_reader :params
  attr_reader :filo
  attr_reader :counter
  attr_reader :end

  def batch_parse(batch = 1000)
    # @csv ||= CSV.new(@filo, col_sep: @params[:comm], quote_char: @params[:quot], liberal_parsing: false, headers: false)
    @counter ||= 0
    res = []
    batch.times do
      line = @filo.gets
      line || next
      line = remove_bad_comma(line) unless @params[:quot]
      line.gsub!(@params[:quot], '') if @params[:quot]
      l= line.split(@params[:comm])
      cost = l[@params[:pos][:cost]].strip
      (puts "Wrong cost!: #{line}"; next) unless check_num(cost)
      stock = l[@params[:pos][:stock]].strip
      (puts "Wrong stock!: #{line}"; next) unless check_num(stock)
      flds =  [
        @price,
        l[@params[:pos][:brand]].to_s.strip.downcase,
        l[@params[:pos][:code]].to_s.strip.downcase,
        stock.gsub('>', '').to_s.strip.to_i,
        (cost.gsub('>', '').to_s.strip.to_f * 100).to_i,
        l[@params[:pos][:name]].to_s.strip
      ]
      (puts "Wrong line!: #{line}"; next) if flds[1].empty? || flds[2].empty? || flds[3] < 0 || flds[4] < 0
      res << flds
      @counter += 1
      break if @filo.eof?
    end
    res
  end

  def check_num(num)
    num !~ /[^\d >,\.]/
  end

  QUOT = '"'
  def remove_bad_comma(line)
    qp = line.index(QUOT)
    unless qp.nil?
      ch = @params[:comm] == ',' ? ';' : ','
      i, l, open = [qp, line.length, false]
      while i < l
        open = !open if line[i] == QUOT
        line[i] = ch if open && line[i] == @params[:comm]
        i += 1
      end
    end
    line
  end

  def initialize(filo, price)
    @price = price
    @params = {
      comm: nil,
      quot: nil,
      pos: {}
    }
    @encoding = `file --mime #{filo}`.strip.split('charset=').last == 'utf-8' ? 'utf-8' : 'windows-1251'
    @filo = File.open(filo, "r:#{@encoding}:utf-8")
  end

  def prepare_header
    @header = @filo.first || return
    @header.strip.gsub(/[^\w а-яА-Я,:;.\-'"`\[\]\(\)]+/, '').downcase!
  end

  def header
    @header || prepare_header
  end

  def set_csv_params(head = self.header)
    %w[; , :].each { |c| (@params[:comm] = c; break) if head.count(c) > 2 }
    return @params unless @params[:comm]
    @params[:quot] = /["|'|`]#{@params[:comm]}["|'|`]/.match(head).to_a[0].to_s[0]
    flds = head.gsub(@params[:quot].to_s, '').split(@params[:comm])
    @params[:pos][:brand] = get_field_num(flds, WORDS_BRAND)
    @params[:pos][:code] = get_field_num(flds, WORDS_CODE)
    @params[:pos][:stock] = get_field_num(flds, WORDS_STOCK)
    @params[:pos][:cost] = get_field_num(flds, WORDS_COST)
    @params[:pos][:name] = get_field_num(flds, WORDS_NAME)
    @params
  end

  def close
    @filo.close
  end

  private

  def get_field_num(flds, templ)
    flds.each_with_index do |fld, i|
      return i if templ.include?(fld.strip)
    end
  end
end