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
    CSV.open("results-#{Date.today}.csv", "ab") do |csv|
        csv << ["File Name", "Cablint Output"]
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
end