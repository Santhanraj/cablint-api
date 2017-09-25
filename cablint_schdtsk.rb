#   Copyright 2017 Santhan Raj
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

lib = File.expand_path("../certlint/lib", __FILE__)
ext = File.expand_path("../certlint/ext", __FILE__)
$:.unshift(lib)
$:.unshift(ext)


require 'certlint'
require 'json'
require 'csv'
require 'date'
require 'openssl'
require 'certlint/version'
require 'certlint/certlint'
require 'certlint/cablint'
require 'certlint/pemlint'
require 'certlint/namelint'
require 'certlint/generalnames'

ER_SKIP = [ 'W: Extension should be critical for KeyUsage',
            'W: Microsoft extension 1.3.6.1.4.1.311.21.7 treated as opaque extension',
            'E: Control character found in String in CertificatePolicies',
            'E: Control character found in String in CPSuri',
            'W: Microsoft extension 1.3.6.1.4.1.311.21.10 treated as opaque extension',
            'I: TLS Server certificate identified',
          ]

def lint(source, inp)
    if source.include? '-BEGIN CERTIFICATE-'
        m, der = CertLint::PEMLint.lint(source, 'CERTIFICATE')
    else
        m  = []
        der = source
    end

    m += CertLint::CABLint.lint(der)
    
    CSV.open("results-#{Date.today}.csv", "ab") do |csv|
        m.each do |msg|
            next if ER_SKIP.include? msg
            begin
                #puts m
                csv << ["#{inp}","#{msg}"]
            rescue Encoding::UndefinedConversionError
                csv << ["#{inp} - there was some error with this file","#{msg}"]
            end
        end

    end
end

begin
    start_time = Time.now()
    unless File.file?("results-#{Date.today}.csv")
        CSV.open("results-#{Date.today}.csv", "ab") do |csv|
            csv << ["File Name", "Cablint Output"]
	    end
	end
    total = Dir[File.join("source", '**', '*')].count { |file| File.file?(file) }
    complete = 1
    progress = 'Progress ['
    Dir.foreach ("source") do |infile|
        next if infile == '.' or infile == '..'
	    inp = File.join("source", "#{infile}")
        raw = File.read(inp)
        lint(raw, infile)
        j = (complete/total) * 1000
        complete += 1
        if j % 10 == 0
            progress << "*"
            print "\r"
            print progress + " #{j / 10}%] "
            $stdout.flush
        end
    end
    puts "Done!"
    end_time = Time.now()
    time_taken = end_time - start_time
    puts "Lint'ed #{total} certificates in #{Time.at(time_taken).utc.strftime("%H:%M:%S.%L")}"
end