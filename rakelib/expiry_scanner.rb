#!/usr/bin/env ruby

require 'find'
require 'openssl'
require 'date'


namespace :expiry_scanner do
  desc 'Expired Certificate Scanner'
    task expired_certificate_scanner: :environment do
      REMAINING_DAYS = 60
      URGENT_REMAINING_DAYS = 30

      verbose = ARGV[1] == '-v'

      cert_paths = []
      Find.find(ARGV[0]) do |path|
        cert_paths << path if ( path =~ /.*\.crt$/ || path =~ /.*\.pem$/ ) && path !~ /.*dgi.+/ && path !~ /.*oauth_lowers_pub.+/ && path !~ /.*oauth_prod_pub.+/
      end

      now = DateTime.now
      cert_paths.each do |cert_path|
        begin
          cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
          expiry = cert.not_after.to_datetime
          subpath = cert_path.sub(ARGV[0], '')
          if now + URGENT_REMAINING_DAYS > expiry
            puts "URGENT: #{subpath} expires in less than #{URGENT_REMAINING_DAYS} days: #{expiry.to_s}"
          elsif now + REMAINING_DAYS > expiry
            puts "ATTENTION: #{subpath} expires in less than #{REMAINING_DAYS} days: #{expiry.to_s}"
          else
            puts "#{subpath} expires: #{expiry.to_s}" if verbose
          end
        rescue => e
          puts "ERROR: Could not parse certificate #{cert_path}"
        end
      end
    end
  end
end

