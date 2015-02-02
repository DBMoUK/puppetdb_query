#!/opt/puppet/bin/ruby

require 'net/http'
require 'optparse'
require 'ostruct'
require 'json'

def parse(args)
  options = OpenStruct.new
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: do_it.rb [options]"
    opts.separator ""
    opts.separator "Specific options:"
    opts.on('--server SERVER','PuppetDB server which to use') do |puppet_server|
      options.server = puppet_server
    end
    opts.on('--ssl-confdir LOCATION','Location of the SSL directory for REST operation usage.',
            'Directories under this must be: certs, private_keys and public_keys') do |ssl_dir|
      options.ssl_confdir = ssl_dir
    end
    opts.on('--cert NAME','Name of certificate to use in REST operations.' '(do not include the pem extension)') do |cert|
      options.certname = cert
    end
    opts.on("-o","--os OSFAMILY", "OS Family to test against") do |os|
      options.os = os
    end
    opts.on("-f","--fact FACT", "Fact to query") do |fact|
      options.fact = fact
    end
    opts.on("-v", "--value VALUE", "Value for which fact is tested against") do |fact_value|
      options.fact_value = fact_value
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opt_parser.parse!(args)
  options
end

def connect_me(port)
  begin
    http = Net::HTTP.new(@server, port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    store = OpenSSL::X509::Store.new
    store.add_cert(OpenSSL::X509::Certificate.new(File.read("#{@confdir}/certs/ca.pem")))
    http.cert_store = store

    http.key = OpenSSL::PKey::RSA.new(File.read("#{@confdir}/private_keys/#{@certname}.pem"))
    http.cert = OpenSSL::X509::Certificate.new(File.read("#{@confdir}/certs/#{@certname}.pem"))
    return http
  rescue Exception => e
    puts "We broke the communications: #{e}"
  end
end


def comms_connection(type, uri)
  begin
    case type
    when /^PUT$/i
      return Net::HTTP::Put.new(uri)
    when /^POST$/i
      return Net::HTTP::Post.new(uri)
    when /^GET$/i
      return Net::HTTP::Get.new(uri)
    when /^DELETE$/i
      return Net::HTTP::Delete.new(uri)
    else fail("#{type} is not a HTTP method")
    end
  rescue Exception => e
    puts "Comms Connection ERROR! #{e}"
  end
end

def get_comms(comms_type, uri, port, body)
  begin
    comms_object = connect_me(port)
    comms_query = comms_connection(comms_type, uri)
    if comms_type =~ /^(POST)|(PUT)|(GET)$/i
      comms_query["Content-Type"] = "application/json"
      comms_query.body = body
    end
    comms_response = comms_object.request(comms_query)
    return comms_response
  rescue Exception => e
    puts "Get Comms ERROR! #{e}"
  end
end

def get_puppetdb_data
  begin
    node_connection = connect_me(8081)
    reply = get_comms('GET',"/v3/nodes", '8081',"{\"query\":[[\"and\",[\"fact\",\"osfamily\"],\"#{@os}\"],[\"=\",[\"fact\",\"#{@fact}\"],\"#{@fact_value}\"]]}")
    if reply.code == '404'
      puts "404: #{reply.body}"
    elsif reply.body
      return JSON.parse(reply.body)
      #return JSON.parse(reply.body)
    else
      puts reply.code
      fail("Unknown failure")
    end
    return 0
  rescue Exception => e
    puts "Query ERROR! #{e}"
  end
end

options = parse(ARGV)
raise OptionParser::MissingArgument if options.server.nil?
raise OptionParser::MissingArgument if options.ssl_confdir.nil?
raise OptionParser::MissingArgument if options.certname.nil?
raise OptionParser::MissingArgument if options.os.nil?
raise OptionParser::MissingArgument if options.fact.nil?
raise OptionParser::MissingArgument if options.fact_value.nil?
@server = options.server
@confdir = options.ssl_confdir
@certname = options.certname
@os = options.os
@fact = options.fact
@fact_value = options.fact_value
total_count = 0
get_puppetdb_data().each do |x|
  puts x['name']
  total_count += 1
end
puts "Total number: #{total_count}"
