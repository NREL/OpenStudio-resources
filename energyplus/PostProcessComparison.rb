require 'openstudio'


data = {}

outofbounds = false

Dir.glob('./*.xml').each do |p|

  attrvector = OpenStudio::Attribute::loadFromXml(OpenStudio::Path.new(p)).get().valueAsAttributeVector();

  attrvector.each do |attr|
    name = attr.name
    if not attr.displayName.empty?
      name = attr.displayName.get
    end

    if data[name].nil?
      data[name] = [attr.valueAsDouble]
    else
      data[name] << attr.valueAsDouble
    end
  end
end

printable = []

printable << ["#{ARGV[0]}"] 
printable << ["Baseline"]

dataitem = 0

data.each do |key, value|
  printable[0] << key 

  for i in (0..value.size-1)
    if i == 0
      printable[1] << value[i]
    else 
      if printable[i*2].nil?
        printable[i*2] = ["Compare"]
        printable[i*2+1] = ["Percent Difference"]
      end

      printable[i*2] << value[i]
      if printable[1][dataitem+1] == 0 && value[i] == 0
        percent = 0
      else
        percent = 100 * (value[i] - printable[1][dataitem+1])/printable[1][dataitem+1]
      end
      printable[i*2+1] << percent
      if percent > 1
        outofbounds = true
      end

    end
  end

  dataitem = dataitem + 1
end


outfile = File.new("comparison_report.csv", "w")
outfile2 = File.new(ARGV[1], "a+")

printable.each do |row|

  row.each do |col|
    outfile.print col
    outfile.print ","

    outfile2.print col
    outfile2.print ","
  end

  outfile.print "\n"
  outfile2.print "\n"

end

outfile2.print "\n\n"

exit !outofbounds
