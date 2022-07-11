#!/usr/bin/env ruby

require 'rubydns'
require 'bigdecimal'
require 'mysql2'
require 'syslog'

$debug = 3

$ttl = 2100

$mysql_hostname = '172.20.30.5'
$mysql_username = 'PxReader'
$mysql_password = 'PxReader'
$mysql_db = 'px'

def log(msg)
  Syslog.log(Syslog::LOG_ERR, '%s', msg)
  warn("STDERR: [ #{msg} ]") if $debug > 0
end

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

def check_domain_in_db(domain)
  res = {}

  arr = domainToQueryArr(domain)

  begin
    db_client = Mysql2::Client.new(host: $mysql_hostname, username: $mysql_username,
                                   password: $mysql_password, database: $mysql_db)
  rescue StandardError => e
    log(e)
    log(e.inspect)
    db_client.close unless db_client.nil?
    return res
  end

  values = "'#{arr.join("', '")}'"

  query = <<~EOF
    SELECT u.url, c.name, c.category_id, c.description  FROM px.url u
    JOIN px.Category c
    ON u.category_id = c.category_id WHERE u.url IN ( #{values} );
  EOF

  results = db_client.query(query)

  if results.size > 0
    results.each do |r|
      res["#{r['category_id']}"] = {} if res["#{r['category_id']}"].nil?

      res["#{r['category_id']}"]['name'] = r['name'] if res["#{r['category_id']}"]['name'].nil?

      if res["#{r['category_id']}"]['description'].nil? && !r['description'].nil?
        res["#{r['category_id']}"]['description'] = r['description']
      end

      res["#{r['category_id']}"]['res'] = [] if res["#{r['category_id']}"]['res'].nil?

      res["#{r['category_id']}"]['res'] << r['url']
      if res["#{r['category_id']}"]['timestamp'].nil?
        #			res["#{r["category_id"]}"]["timestamp"] = Time.now.getutc
        res["#{r['category_id']}"]['timestamp'] = Time.now.getutc.to_i
      end
    end
  end

  db_client.close unless db_client.nil?
  res
end

STDOUT.sync = true
Syslog.open("#{$PROGRAM_NAME}", Syslog::LOG_PID)
log("Started with DEBUG => #{$debug}")

INTERFACES = [
  [:udp, '0.0.0.0', 10_053],
  [:tcp, '0.0.0.0', 10_053]
]

IN = Resolv::DNS::Resource::IN

# Use upstream DNS for name resolution.
UPSTREAM = RubyDNS::Resolver.new([[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])

# Start the RubyDNS server
RubyDNS.run_server(INTERFACES) do
  match(/\.f\.ngtech\.co\.il$/, IN::A) do |transaction|
    res = transaction.name.scan(/(.*)\.f\.ngtech\.co\.il$/)
    db_res = check_domain_in_db(res[0][0])
    transaction_res = []

    db_res.each do |k, _v|
      transaction_res << k
    end
    puts(transaction_res)

    if transaction_res.size > 0
      transaction_res.each do |a|
        transaction.respond!("127.0.0.#{a}", ttl: $ttl)
      end
    end
  end

  match(/\.f\.ngtech\.co\.il$/, IN::TXT) do |transaction|
    res = transaction.name.scan(/(.*)\.f\.ngtech\.co\.il$/)

    db_res = check_domain_in_db(res[0][0])

    transaction_res = []

    db_res.each do |k, v|
      transaction_res << if v['description'].nil?
                           "#{k}:#{v['name']}::#{v['timestamp']}"
                         else
                           "#{k}:#{v['name']}:#{v['description']}:#{v['timestamp']}"

                         end
    end

    if transaction_res.size > 0
      transaction_res.each do |a|
        transaction.respond!(a, resource_class: IN::TXT, ttl: $ttl)
      end
    end
  end
end
