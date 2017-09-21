lib = File.expand_path("../../certlint/lib", __FILE__)
ext = File.expand_path("../../certlint/ext", __FILE__)
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

def lint(source, inp)
    
    if source.include? '-BEGIN CERTIFICATE-'
        m, der = CertLint::PEMLint.lint(source, 'CERTIFICATE')
    else
        m  = []
        der = source
    end

    m += CertLint::CABLint.lint(der)
    
    CSV.open("output.csv", "ab") do |csv|
        m.each do |msg|
            next if msg == ""
            begin
                csv << ["#{inp}","#{msg}"]
            rescue Encoding::UndefinedConversionError
                csv << ["#{inp} - there was some error with this file","#{msg}"]
        end
    end

end

begin
    CSV.open("results-#{Date.today}.csv", "ab") do |csv|
        csv << ["File Name", "Cablint Output"]
	end
    
    Dir.foreach (ARGV[0]) do |infile|
        next if infile == '.' or infile == '..'
	    inp = File.join("#{ARGV[0]}", "#{infile}")
        raw = File.read(inp)
        lint(raw, infile)
    end
end
end
