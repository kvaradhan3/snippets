#! /usr/bin/env ruby

#
# forms an address pool out of acidr block and allocates.
#

require 'ipaddr'
class MySubnets
    def initialize(ipaddrfd)
        @f = ipaddrfd
        @ipaddrmask = nil
    end

    def getnext
        x = nil
        loop do
            if @ipaddrmask.nil? then
                @ipaddrmask = next_addr_block
            end

            begin
                x = @ipaddrmask.next
            rescue StopIteration
                @ipaddrmask = nil
                redo
            else
                break
            end
        end
        return x.to_s
    end

    private

    def next_addr_block
        com = [ "#", ":", "%", "//" ]
        begin
            @f.each do |line|
                line.chomp!.strip!
                next if line.empty? || com.any? { |c| line =~ /^#{c}/ }
                return IPAddr.new(line.chomp).to_range.each
            end
        rescue EOFError
            return nil
        end
        return nil
    end
end

if ARGV.empty? then
    x = MySubnets.new(DATA)
else
    x = MySubnets.new(File.open(ARGV[0], "r"))
end
1.upto(20) { |i| puts("#{i}	" + x.getnext()) }


__END__
#
# You can use the below IP’s, we have attached to A5s1 server for
# tracking purposes.

# Subnet: 10.84.14.0
# Mask: 255.255.255.0
# GW: 10.84.14.254

# a5s1            |a5s1-vm1.englab.juniper.net      |10.84.14.101   |
# a5s1            |a5s1-vm2.englab.juniper.net      |10.84.14.102   |
# a5s1            |a5s1-vm3.englab.juniper.net      |10.84.14.103   |
# a5s1            |a5s1-vm4.englab.juniper.net      |10.84.14.104   |
# a5s1            |a5s1-vm5.englab.juniper.net      |10.84.14.105   |
# a5s1            |a5s1-vm6.englab.juniper.net      |10.84.14.106   |
# a5s1            |a5s1-vm7.englab.juniper.net      |10.84.14.107   |
# a5s1            |a5s1-vm8.englab.juniper.net      |10.84.14.108   |
# a5s1            |a5s1-vm9.englab.juniper.net      |10.84.14.109   |
# a5s1            |a5s1-vm10.englab.juniper.net     |10.84.14.110   |
# a5s1            |a5s1-vm11.englab.juniper.net     |10.84.14.111   |
# a5s1            |a5s1-vm12.englab.juniper.net     |10.84.14.112   |
# a5s1            |a5s1-vm13.englab.juniper.net     |10.84.14.113   |
# a5s1            |a5s1-vm14.englab.juniper.net     |10.84.14.114   |
# a5s1            |a5s1-vm15.englab.juniper.net     |10.84.14.115   |
# a5s1            |a5s1-vm16.englab.juniper.net     |10.84.14.116   |

10.84.14.101
10.84.14.102
10.84.14.103
10.84.14.104/29
10.84.14.112/30
10.84.14.116
