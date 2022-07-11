#!/usr/bin/env ruby

require 'rubydns'

$lists = {}

$ttl = 2100

require "#{__dir__}/load-lists.rb"

def domainToQueryArr(domain)
  queryDoms = []
  queryDoms << domain

  arr = domain.split('.')
  i = arr.size - 1

  while i > -1
    queryDoms << ".#{arr[i..arr.size - 1].join('.')}"
    i -= 1
  end
  queryDoms
end

INTERFACES = [
  [:udp, '0.0.0.0', 10053],
  [:tcp, '0.0.0.0', 10053]
]

IN = Resolv::DNS::Resource::IN

# Use upstream DNS for name resolution.
UPSTREAM = RubyDNS::Resolver.new([[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])

# Start the RubyDNS server
RubyDNS.run_server(INTERFACES) do
  match(/\.f\.ngtech\.co\.il$/, IN::A) do |transaction|
    res = transaction.name.scan(/(.*)\.f\.ngtech\.co\.il$/)

    domains_arr = domainToQueryArr(res[0][0])
    transation_res = []
    $lists.each do |k, v|
      transation_res << k if v['list'].intersection(domains_arr).size > 0
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
      transation_res << "#{k}:#{v['description']}:#{v['timestamp']}" if v['list'].intersection(domains_arr).size > 0
    end
    if transation_res.size > 0
      transation_res.each do |a|
        transaction.respond!(a, resource_class: IN::TXT, ttl: $ttl)
      end
    end
  end
end
