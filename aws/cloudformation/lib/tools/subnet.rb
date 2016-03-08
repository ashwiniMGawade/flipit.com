require 'netaddr'

def subnet(net=nil)
  bits ||= ENV['VPC_SUBNET_BITS'].to_i

  vpc_subnet = NetAddr::CIDRv4.create ENV['VPC_CIDR']

  if net.nil?
    vpc_subnet.to_s
  elsif net.is_a? String
    (NetAddr::CIDRv4.create net).to_s
  else
    vpc_subnet.subnet(Bits: bits)[net.to_i].to_s
  end
end

def ip(net, addr)
  NetAddr::CIDRv4.create(subnet(net)).nth(addr).to_s
end
