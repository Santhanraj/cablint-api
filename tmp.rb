def lint
    message = %x[ruby ../certlint/bin/cablint test.cer]
    puts message
end

lint
