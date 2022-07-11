#!/usr/bin/env ruby

require 'rubydns'


$lists = {}

$lists["59"] = { "timestamp" => "1657409402", "description" => "Porn", "list" => [] }

str = <<EOF
.-bondoge-phitelesano.cgay-le.com
.-hot.bondagetopless.com
.-ila-.mondocamgirls.com
.-julymodele-.cmonbook.com
.-las-mejores-enculadas.fadlan.com
.-lilo-og-stitc-porno.solvebowl.he.cn
.-p.coy-sex-sce.com
.-sexlebdahorny-le.com
.-sexlebdahot-le.com
.-sexoretvous-.i-gloo.net
.youporn.com
EOF

$lists["59"]["list"] = str.split("\n")


$lists["60"] = { "timestamp" => "1657409402", "description" => "Advertising", "list" => [] }

str =<<EOF
.0-008.info
.0-0to.com
.0-168.com
.0-2u.com
.linestreamx.com
.0-a.us
.0-advertising.com
.0-banners.com
.0-computer.info
.0-credit.info
.0-go.com
.0-money.us
.0.r.msn.com
.00.img.torg.st
.0000webhost.com
.00037.accountant
EOF

$lists["60"]["list"] = str.split("\n")

$ttl = 2100

require "#{__dir__}/load-lists.rb"

def domainToQueryArr(domain)
        queryDoms = []
        queryDoms << domain

        arr = domain.split('.')
        i = arr.size - 1

        while i > -1 do
                queryDoms << ".#{arr[i..arr.size-1].join(".")}"
                i = i -1
        end
        return queryDoms
end


INTERFACES = [
	[:udp, "0.0.0.0", 53],
	[:tcp, "0.0.0.0", 53],
]

IN = Resolv::DNS::Resource::IN


# Use upstream DNS for name resolution.
UPSTREAM = RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])

# Start the RubyDNS server
RubyDNS::run_server(INTERFACES) do
	match(/\.f\.ngtech\.co\.il$/, IN::A) do |transaction|
		res = transaction.name.scan(/(.*)\.f\.ngtech\.co\.il$/)

		domains_arr = domainToQueryArr(res[0][0])
		transation_res = []
		$lists.each do |k, v|
			if v["list"].intersection(domains_arr).size > 0
				transation_res << k
			end
		end
  		if transation_res.size > 0
			transation_res.each do |a|
				transaction.respond!("127.0.0.#{a}", ttl: $ttl)
			end
		end
	end

	match(/\.f\.ngtech\.co\.il$/, IN::TXT) do |transaction|
		res = transaction.name.scan(/(.*)\.f\.ngtech\.co\.il$/)

                domains_arr = domainToQueryArr(res[0][0])
                transation_res = []
                $lists.each do |k, v|
                        if v["list"].intersection(domains_arr).size > 0
                                transation_res << "#{k}:#{v["description"]}:#{v["timestamp"]}"
                        end
                end
                if transation_res.size > 0
                        transation_res.each do |a|
				transaction.respond!(a, resource_class: IN::TXT, ttl: $ttl )

                        end
                end
	end

end
